#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <thread>

// Minimal ConPTY-based host. Creates a child window, sets parent to provided HWND (if any),
// starts cmd.exe attached to the pseudo console, forwards basic input/output.

typedef HRESULT (WINAPI *CreatePseudoConsole_t)(COORD, HANDLE, HANDLE, DWORD, HPCON*);
typedef HRESULT (WINAPI *ClosePseudoConsole_t)(HPCON);

// PROC_THREAD_ATTRIBUTE list macros
#ifndef PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE
#define PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE ((DWORD)0x00020016)
#endif

static CreatePseudoConsole_t pCreatePseudoConsole = nullptr;
static ClosePseudoConsole_t pClosePseudoConsole = nullptr;

// Simple helper to write to pipe
static bool WriteAll(HANDLE h, const char* buf, DWORD len) {
    DWORD written = 0;
    return !!WriteFile(h, buf, len, &written, NULL);
}

LRESULT CALLBACK HostWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    default:
        return DefWindowProc(hWnd, msg, wParam, lParam);
    }
}

int wmain(int argc, wchar_t** argv) {
    // optional host HWND as decimal value
    HWND hostParent = NULL;
    if (argc >= 2) {
        unsigned long long val = _wcstoui64(argv[1], NULL, 0);
        hostParent = (HWND)(uintptr_t)val;
    }

    HMODULE k32 = GetModuleHandleW(L"kernel32.dll");
    if (k32) {
        pCreatePseudoConsole = (CreatePseudoConsole_t)GetProcAddress(k32, "CreatePseudoConsole");
        pClosePseudoConsole = (ClosePseudoConsole_t)GetProcAddress(k32, "ClosePseudoConsole");
    }
    if (!pCreatePseudoConsole) {
        std::cerr << "CreatePseudoConsole not available on this system." << std::endl;
        return 2;
    }

    // Create window class for host
    WNDCLASSW wc = {};
    wc.lpfnWndProc = HostWndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = L"ConPTYHostWndClass";
    RegisterClassW(&wc);

    HWND hostWnd = CreateWindowExW(0, wc.lpszClassName, L"ConPTYHost", WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 400, NULL, NULL, wc.hInstance, NULL);

    if (!hostWnd) {
        std::cerr << "Failed to create host window" << std::endl;
        return 3;
    }

    if (hostParent) {
        // attach as child to provided host HWND
        SetWindowLongPtrW(hostWnd, GWL_STYLE, WS_CHILD | WS_VISIBLE);
        SetParent(hostWnd, hostParent);
    }

    // Pipes for ConPTY
    HANDLE inPipeRead = NULL, inPipeWrite = NULL;
    HANDLE outPipeRead = NULL, outPipeWrite = NULL;
    SECURITY_ATTRIBUTES sa{ sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };

    if (!CreatePipe(&inPipeRead, &inPipeWrite, &sa, 0)) { std::cerr<<"CreatePipe in failed"<<std::endl; return 4; }
    if (!CreatePipe(&outPipeRead, &outPipeWrite, &sa, 0)) { std::cerr<<"CreatePipe out failed"<<std::endl; return 5; }

    // Create the pseudo console
    COORD size{80, 25};
    HPCON hPC = NULL;
    HRESULT hr = pCreatePseudoConsole(size, inPipeRead, outPipeWrite, 0, &hPC);
    if (FAILED(hr) || !hPC) { std::cerr<<"CreatePseudoConsole failed"<<std::endl; return 6; }

    // Prepare attribute list for child process
    SIZE_T attrListSize = 0;
    InitializeProcThreadAttributeList(NULL, 1, 0, &attrListSize);
    LPPROC_THREAD_ATTRIBUTE_LIST attrList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, attrListSize);
    if (!InitializeProcThreadAttributeList(attrList, 1, 0, &attrListSize)) { std::cerr<<"Init attr list failed"<<std::endl; return 7; }
    if (!UpdateProcThreadAttribute(attrList, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, hPC, sizeof(HPCON), NULL, NULL)) { std::cerr<<"UpdateProcThreadAttribute failed"<<std::endl; return 8; }

    // Create the child process (cmd.exe)
    STARTUPINFOEXW siex{};
    siex.StartupInfo.cb = sizeof(siex);
    siex.lpAttributeList = attrList;

    PROCESS_INFORMATION pi{};
    std::wstring cmd = L"C:\\Windows\\System32\\cmd.exe";
    BOOL ok = CreateProcessW(NULL, &cmd[0], NULL, NULL, FALSE, EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, &siex.StartupInfo, &pi);
    if (!ok) { std::cerr<<"CreateProcessW failed: "<< GetLastError() << std::endl; /* cleanup */ pClosePseudoConsole(hPC); return 9; }

    // Close handles we don't need
    CloseHandle(inPipeRead);
    CloseHandle(outPipeWrite);

    // Thread to read output from the conpty and forward to this process stdout
    std::thread conpty_to_stdout([&]() {
        const int bufSize = 4096;
        std::vector<char> buf(bufSize);
        HANDLE stdOut = GetStdHandle(STD_OUTPUT_HANDLE);
        while (true) {
            DWORD n = 0;
            if (!ReadFile(outPipeRead, buf.data(), bufSize, &n, NULL) || n == 0) break;
            // write to this process stdout so parent (Dart) can read it
            DWORD written = 0;
            WriteFile(stdOut, buf.data(), n, &written, NULL);
            // also update window title (short preview)
            std::string s(buf.data(), (size_t)n);
            for (auto &ch : s) if (ch == '\r' || ch == '\n') ch = ' ';
            SetWindowTextA(hostWnd, s.c_str());
        }
    });

    // Thread to read our stdin (parent wrote to helper.stdin) and forward into the conpty input
    std::thread stdin_to_conpty([&]() {
        const int bufSize = 4096;
        std::vector<char> buf(bufSize);
        HANDLE stdIn = GetStdHandle(STD_INPUT_HANDLE);
        DWORD n = 0;
        while (true) {
            if (!ReadFile(stdIn, buf.data(), bufSize, &n, NULL) || n == 0) break;
            // forward to conpty
            if (n > 0) {
                WriteAll(inPipeWrite, buf.data(), n);
            }
        }
    });

    // Basic message loop
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    // Cleanup
    // Signal pipes closed
    CloseHandle(inPipeWrite);
    CloseHandle(outPipeRead);
    if (pi.hProcess) CloseHandle(pi.hProcess);
    if (pi.hThread) CloseHandle(pi.hThread);
    if (attrList) { DeleteProcThreadAttributeList(attrList); HeapFree(GetProcessHeap(), 0, attrList); }
    if (hPC && pClosePseudoConsole) pClosePseudoConsole(hPC);
    if (conpty_to_stdout.joinable()) conpty_to_stdout.join();
    if (stdin_to_conpty.joinable()) stdin_to_conpty.join();

    return 0;
}

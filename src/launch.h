#pragma once
#ifndef LAUNCH_H
#define LAUNCH_H

#define DEBUG 0

#ifdef _MSC_VER
#define MSVC
#endif

#include <iostream>
#include <stdlib.h>
#include <string>
#include <windows.h>
#include <sddl.h>
#include <tchar.h>

BOOL IsRunAsAdmin();
void Message();
void ElevatePrivileges();
void RunMainBat();

#endif // LAUNCH_H

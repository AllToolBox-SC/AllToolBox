#pragma once
#ifndef LAUNCH_H
#define LAUNCH_H

#define DEBUG 0

#include <iostream>
#include <stdlib.h>
#include <string>
#include <windows.h>
#include <sddl.h>

BOOL IsRunAsAdmin();
void Message();
void ElevatePrivileges();
void RunMainBat();

#endif // LAUNCH_H

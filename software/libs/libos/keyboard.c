// 
// Copyright 2015 Jeff Bush
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 

#include "keyboard.h"

// PS/2 scancodes, set 2
static const unsigned char kNormalScancodeTable[] = {
	0, KBD_F9, 0, KBD_F5, KBD_F3, KBD_F1, KBD_F2, KBD_F12, 0, KBD_F10, KBD_F8, KBD_F6, KBD_F4, '\t', 
	'`', 0, 0, KBD_LALT, KBD_LSHIFT, 0, 0, 'q', '1', 0, 0, 0, 'z', 's', 'a', 'w', '2', 0, 0, 'c', 'x', 
	'd', 'e', '4', '3', 0, 0, ' ', 'v', 'f', 't', 'r', '5', 0, 0, 'n', 'b', 'h', 'g', 'y', '6', 0, 0, 0, 
	'm', 'j', 'u', '7', '8', 0, 0, 0, 'k', 'i', 'o', '0', '9', 0, 0, 0, 0, 'l', 0, 'p', '-', 0, 
	0, 0, 0, 0, 0, '=', 0, 0, 0, KBD_RSHIFT, '\n', 0, 0, '\\', 0, 0, 0, 0, 0, 0, 0, 0, 8, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '\x27', 0, KBD_F11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	KBD_F7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static const unsigned char kExtendedScancodeTable[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, KBD_RALT, 0, 0, KBD_RCTRL, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, KBD_LEFTARROW, 0, 0, 0, 
	0, 0, 0, KBD_DOWNARROW, 0, KBD_RIGHTARROW, KBD_UPARROW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0	
};

static volatile unsigned int * const REGISTERS = (volatile unsigned int*) 0xffff0000;
static int isExtendedCode = 0;
static int isRelease = 0;

unsigned int pollKeyboard(void)
{
	// Read keyboard
	while (REGISTERS[0x38 / 4])
	{
		unsigned int code = REGISTERS[0x3c / 4];
		if (code == 0xe0)
			isExtendedCode = 1;
		else if (code == 0xf0)
			isRelease = 1;
		else
		{
			int result;
			if (isExtendedCode)
				result = kExtendedScancodeTable[code];
			else
				result = kNormalScancodeTable[code];

			if (!isRelease)
				result |= KBD_PRESSED;
			
			isExtendedCode = 0;
			isRelease = 0;
			return result;
		}
	}
	
	return 0xffffffff;
}



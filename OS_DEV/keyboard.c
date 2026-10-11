#include "keyboard.h"
#include "print.h"
#include "process.h"

#define POUND 0x9C

static unsigned char shift_code[256] = 
{
  [0x2A] = SHIFT, [0x36] = SHIFT, [0xAA] = SHIFT, [0xB6] = SHIFT
};

static unsigned char lock_code[256] =
{
  [0x3A] = CAPS_LOCK
};


static char key_map[256] = {
    0,    0,    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    '-',  '=',  '\b', '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u',
    'i',  'o',  'p', '[', ']', '\n', 0,   'a', 's', 'd', 'f',
    'g',  'h',  'j', 'k', 'l', ';', '\'', '`', 0,   '#', 'z',
    'x',  'c',  'v', 'b', 'n', 'm', ',', '.', '/', 0,   '*', 0, ' ',
    [0x56] = '\\'
};

static char shift_key_map[256] = {
    0, 0, '!', '"', POUND, '$', '%', '^', '&', '*', '(', ')',
    '_', '+', '\b', ' ', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U',
    'I', 'O', 'P', '{', '}', '\n', '\n', 'A', 'S', 'D', 'F', 'G',
    'H', 'J', 'K', 'L', ':', '@', 0, '|', '~' ,'Z', 'X', 'C',
    'V', 'B', 'N', 'M', '<', '>', '?', 0, ' ',
    [0x56] = '|'
};

static unsigned int flag;

static unsigned char keyboard_read(void)
{
    unsigned char scan_code;
    char ch;

    scan_code = in_byte(0x60); //# this makes scan_code read the serial byte at 0x60
    if (scan_code == 0xE0) {   //# if the scan code is 0xE0 (the 0xE0 is extended sign, warning the next byte is the extended keyboard code) 
        flag |= E0_SIGN;       // it does the OR bitwise with current flag value 
        return 0;		//THIS IS WHERE THE CODE FOR HANDLING THE ARROW KEYS GO !!!!!!!
    }

    if (flag & E0_SIGN) {
        flag &= ~E0_SIGN;
	if(scan_code & 0x80)
	{
		return 0;
	}
	switch(scan_code)
	{
		case 0x48: return UP;
		case 0x50: return DOWN;
		case 0x4B: return LEFT;
		case 0x4D: return RIGHT;
		default: return 0;
	}
		
    }

    if (scan_code & 0x80) {
        flag &= ~(shift_code[scan_code]);	// this saves state of the flag, for if caps and shift are used, turns the 0x04(caps on) to 0x06(caps and shift pressed) 
        return 0;				// but then when shift is released, it does the & ~ which compliments the bits and can set 0x06 back to 0x04 for just caps
    }

    flag |= shift_code[scan_code];
    flag ^= lock_code[scan_code];

    if (flag & SHIFT) {
        ch = shift_key_map[scan_code];
    }
    else {
        ch = key_map[scan_code];
    }
    
    if (flag & CAPS_LOCK) { 
        if('a' <= ch && ch <= 'z')
            ch -= 32;
        else if('A' <= ch && ch <= 'Z')
            ch += 32;
    }

    return ch;
}

void keyboard_handler(void)
{
  unsigned char ch[2] = { 0 };
  ch[0] = keyboard_read();
  
  if(ch[0] != 0)
  {
    printk("%s", ch);
  }
}

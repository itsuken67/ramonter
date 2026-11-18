#pragma once

extern void syscall_init();

void print(char* _str);

inline void syscall_return(uint32_t _ret) {
    __asm__ volatile (
        "movl %0, %%eax\n"
        :
    : "m"(_ret)
        :
        );
}

void syscall_proc() {
	uint32_t EAX, EBX, ECX, EDX;
    __asm__ volatile (
        "movl %%eax, %0\n\t"
        "movl %%ebx, %1\n\t"
        "movl %%ecx, %2\n\t"
        "movl %%edx, %3\n\t"
        : "=m" (EAX), "=m" (EBX), "=m" (ECX), "=m" (EDX)
        : 
        :
        );
    switch (EAX & 0xFF)
    {
     //print
    case 0x03:
        print((char*)EDX);
        break;
     //get
    case 0x04:
        asm volatile ("sti");
        syscall_return((uint32_t)get());
        asm volatile ("cli");
        break;
    // write file
    case 0x13:
        break;
    // read file
    case 0x14:
        break;
    // format disk
    case 0x21:
        break;
    default:
        break;
    }
}

void initialize_syscalls() {
	set_idt_entry(0x30, (uint32_t)&syscall_init, 0x0008, 0x8E);
	print("Syscalls initialized\n");
}

uint32_t syscall(uint32_t _eax, uint32_t _ebx, uint32_t _ecx, uint32_t _edx) {
    uint32_t result;
    __asm__ volatile (
        "int $0x30\n"
        : "=a"(result)
    : "a"(_eax), "b"(_ebx), "c"(_ecx), "d"(_edx)
        : "memory"
        );
    return result;
}
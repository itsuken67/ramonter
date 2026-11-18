void* memset(void* _dest, char* _symb, uint32_t _count) {
	asm volatile (
		"rep stosb\n"
		:
		: "c"(_count), "a"(*_symb), "D"(_dest)
		: "memory"
		);
	return _dest;
}

void* memcpy(void* _src, void* _dest, uint32_t _count) {
	for (int i = 0; i < _count; ++i) {
		*((uint8_t*)_dest) = *((uint8_t*)_src);
	}
	return _dest;
}
; program to swap values at data locations

.ORG 0
	LOAD R0, [ff]
	LOAD R1, [fa]
	LOAD R2, [da]
	LOAD R3, [do]
	STR  R0, [do]
	STR  R1, [da]
	STR  R2, [fa]
	STR  R3, [ff]

.ORG 12
	DATA ff, 0xFF
	DATA fa, 0xFA
	DATA da, 0xDA
	DATA do, 0xD0

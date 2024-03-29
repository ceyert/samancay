
ORG 0x7c00
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

times 33 db 0

start:
    jmp 0:step2 


step2:
    cli ; clear interrupts
    mov ax, 0x00 ; hold address
    mov ds, ax ; set data segment
    mov es, ax ; extra segment
    mov ss, ax ; set stack segment
    mov sp, 0x7c00 ; set pointer to 0x7c00
    sti ; enables interrupts

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32
    ;jmp $


; GDT https://wiki.osdev.org/Protected_Mode
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:           ; CS should point this label
    dw 0xffff       ; segment limit 0-15 bits
    dw 0            ; base 0-15 bits
    db 0            ; base 16-23 bits
    db 0x9a         ; access byte
    db 11001111b    ; high 4 bits flags and the low 4 bit flags
    db 0            ; base 24-31 bits

; offset 0x10
gdt_data:           ; DS, SS, ES, FS, GS
    dw 0xffff       ; segment limit 0-15 bits
    dw 0            ; base 0-15 bits
    db 0            ; base 16-23 bits
    db 0x92         ; access byte
    db 11001111b    ; high 4 bits flags and the low 4 bit flags
    db 0            ; base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start


[BITS 32]
load32:
    mov eax, 1          ; starting sector
    mov ecx, 100        ; total sectors we want to load
    mov edi, 0x0100000  ; address we want to load
    call ata_lba_read
    jmp CODE_SEG:0x0100000







; From OS Dev (https://wiki.osdev.org/ATA_read/write_sectors)

ata_lba_read:
     mov ebx, eax, ; Backup the LBA
    ; Send the highest 8 bits of the lba to hard disk controller
    shr eax, 24
    or eax, 0xE0 ; Select the  master drive
    mov dx, 0x1F6
    out dx, al
    ; Finished sending the highest 8 bits of the lba

    ; Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; Finished sending the total sectors to read

    ; Send more bits of the LBA
    mov eax, ebx ; Restore the backup LBA
    mov dx, 0x1F3
    out dx, al
    ; Finished sending more bits of the LBA

    ; Send more bits of the LBA
    mov dx, 0x1F4
    mov eax, ebx ; Restore the backup LBA
    shr eax, 8
    out dx, al
    ; Finished sending more bits of the LBA

    ; Send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx ; Restore the backup LBA
    shr eax, 16
    out dx, al
    ; Finished sending upper 16 bits of the LBA

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

; Read all sectors into memory
.next_sector:
    push ecx

; Checking if we need to read
.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again

; We need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ; End of reading sectors into memory
    ret












times 510-($ - $$) db 0 ; fill 510 bytes with zeroes.
dw 0xAA55 ; boot signature

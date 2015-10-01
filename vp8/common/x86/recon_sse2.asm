;
;  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
;
;  Use of this source code is governed by a BSD-style license
;  that can be found in the LICENSE file in the root of the source
;  tree. An additional intellectual property rights grant can be found
;  in the file PATENTS.  All contributing project authors may
;  be found in the AUTHORS file in the root of the source tree.
;


%include "vpx_ports/x86_abi_support.asm"

;void copy_mem16x16_sse2(
;    unsigned char *src,
;    int src_stride,
;    unsigned char *dst,
;    int dst_stride
;    )
global sym(vp8_copy_mem16x16_sse2) PRIVATE
sym(vp8_copy_mem16x16_sse2):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 4
    push        rsi
    push        rdi
    ; end prolog

        mov         rsi,        arg(0) ;src;
        movdqu      xmm0,       [rsi]

        movsxd      rax,        dword ptr arg(1) ;src_stride;
        mov         rdi,        arg(2) ;dst;

        movdqu      xmm1,       [rsi+rax]
        movdqu      xmm2,       [rsi+rax*2]

        movsxd      rcx,        dword ptr arg(3) ;dst_stride
        lea         rsi,        [rsi+rax*2]

        movdqa      [rdi],      xmm0
        add         rsi,        rax

        movdqa      [rdi+rcx],  xmm1
        movdqa      [rdi+rcx*2],xmm2

        lea         rdi,        [rdi+rcx*2]
        movdqu      xmm3,       [rsi]

        add         rdi,        rcx
        movdqu      xmm4,       [rsi+rax]

        movdqu      xmm5,       [rsi+rax*2]
        lea         rsi,        [rsi+rax*2]

        movdqa      [rdi],  xmm3
        add         rsi,        rax

        movdqa      [rdi+rcx],  xmm4
        movdqa      [rdi+rcx*2],xmm5

        lea         rdi,        [rdi+rcx*2]
        movdqu      xmm0,       [rsi]

        add         rdi,        rcx
        movdqu      xmm1,       [rsi+rax]

        movdqu      xmm2,       [rsi+rax*2]
        lea         rsi,        [rsi+rax*2]

        movdqa      [rdi],      xmm0
        add         rsi,        rax

        movdqa      [rdi+rcx],  xmm1

        movdqa      [rdi+rcx*2],    xmm2
        movdqu      xmm3,       [rsi]

        movdqu      xmm4,       [rsi+rax]
        lea         rdi,        [rdi+rcx*2]

        add         rdi,        rcx
        movdqu      xmm5,       [rsi+rax*2]

        lea         rsi,        [rsi+rax*2]
        movdqa      [rdi],  xmm3

        add         rsi,        rax
        movdqa      [rdi+rcx],  xmm4

        movdqa      [rdi+rcx*2],xmm5
        movdqu      xmm0,       [rsi]

        lea         rdi,        [rdi+rcx*2]
        movdqu      xmm1,       [rsi+rax]

        add         rdi,        rcx
        movdqu      xmm2,       [rsi+rax*2]

        lea         rsi,        [rsi+rax*2]
        movdqa      [rdi],      xmm0

        movdqa      [rdi+rcx],  xmm1
        movdqa      [rdi+rcx*2],xmm2

        movdqu      xmm3,       [rsi+rax]
        lea         rdi,        [rdi+rcx*2]

        movdqa      [rdi+rcx],  xmm3

    ; begin epilog
    pop rdi
    pop rsi
    UNSHADOW_ARGS
    pop         rbp
    ret


;void vp8_intra_pred_uv_dc_mmx2(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
global sym(vp8_intra_pred_uv_dc_mmx2) PRIVATE
sym(vp8_intra_pred_uv_dc_mmx2):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    push        rsi
    push        rdi
    ; end prolog

    ; from top
    mov         rdi,        arg(2) ;above;
    mov         rsi,        arg(3) ;left;
    movsxd      rax,        dword ptr arg(4) ;left_stride;
    pxor        mm0,        mm0
    movq        mm1,        [rdi]
    lea         rdi,        [rax*3]
    psadbw      mm1,        mm0
    ; from left
    movzx       ecx,        byte [rsi]
    movzx       edx,        byte [rsi+rax*1]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax*2]
    add         ecx,        edx

    movzx       edx,        byte [rsi+rdi]
    lea         rsi,        [rsi+rax*4]
    add         ecx,        edx
    movzx       edx,        byte [rsi]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax*2]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rdi]
    add         ecx,        edx

    ; add up
    pextrw      edx,        mm1, 0x0
    lea         edx,        [edx+ecx+8]
    sar         edx,        4
    movd        mm1,        edx
    movsxd      rcx,        dword ptr arg(1) ;dst_stride
    pshufw      mm1,        mm1, 0x0
    mov         rdi,        arg(0) ;dst;
    packuswb    mm1,        mm1

    ; write out
    lea         rax,        [rcx*3]
    lea         rdx,        [rdi+rcx*4]

    movq [rdi      ],       mm1
    movq [rdi+rcx  ],       mm1
    movq [rdi+rcx*2],       mm1
    movq [rdi+rax  ],       mm1
    movq [rdx      ],       mm1
    movq [rdx+rcx  ],       mm1
    movq [rdx+rcx*2],       mm1
    movq [rdx+rax  ],       mm1

    ; begin epilog
    pop         rdi
    pop         rsi
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_intra_pred_uv_dctop_mmx2(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
global sym(vp8_intra_pred_uv_dctop_mmx2) PRIVATE
sym(vp8_intra_pred_uv_dctop_mmx2):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    GET_GOT     rbx
    push        rsi
    push        rdi
    ; end prolog

    ;arg(3), arg(4) not used

    ; from top
    mov         rsi,        arg(2) ;above;
    pxor        mm0,        mm0
    movq        mm1,        [rsi]
    psadbw      mm1,        mm0

    ; add up
    paddw       mm1,        [GLOBAL(dc_4)]
    psraw       mm1,        3
    pshufw      mm1,        mm1, 0x0
    packuswb    mm1,        mm1

    ; write out
    mov         rdi,        arg(0) ;dst;
    movsxd      rcx,        dword ptr arg(1) ;dst_stride
    lea         rax,        [rcx*3]

    movq [rdi      ],       mm1
    movq [rdi+rcx  ],       mm1
    movq [rdi+rcx*2],       mm1
    movq [rdi+rax  ],       mm1
    lea         rdi,        [rdi+rcx*4]
    movq [rdi      ],       mm1
    movq [rdi+rcx  ],       mm1
    movq [rdi+rcx*2],       mm1
    movq [rdi+rax  ],       mm1

    ; begin epilog
    pop         rdi
    pop         rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_intra_pred_uv_dcleft_mmx2(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
global sym(vp8_intra_pred_uv_dcleft_mmx2) PRIVATE
sym(vp8_intra_pred_uv_dcleft_mmx2):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    push        rsi
    push        rdi
    ; end prolog

    ;arg(2) not used

    ; from left
    mov         rsi,        arg(3) ;left;
    movsxd      rax,        dword ptr arg(4) ;left_stride;
    lea         rdi,        [rax*3]
    movzx       ecx,        byte [rsi]
    movzx       edx,        byte [rsi+rax]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax*2]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rdi]
    add         ecx,        edx
    lea         rsi,        [rsi+rax*4]
    movzx       edx,        byte [rsi]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rax*2]
    add         ecx,        edx
    movzx       edx,        byte [rsi+rdi]
    lea         edx,        [ecx+edx+4]

    ; add up
    shr         edx,        3
    movd        mm1,        edx
    pshufw      mm1,        mm1, 0x0
    packuswb    mm1,        mm1

    ; write out
    mov         rdi,        arg(0) ;dst;
    movsxd      rcx,        dword ptr arg(1) ;dst_stride
    lea         rax,        [rcx*3]

    movq [rdi      ],       mm1
    movq [rdi+rcx  ],       mm1
    movq [rdi+rcx*2],       mm1
    movq [rdi+rax  ],       mm1
    lea         rdi,        [rdi+rcx*4]
    movq [rdi      ],       mm1
    movq [rdi+rcx  ],       mm1
    movq [rdi+rcx*2],       mm1
    movq [rdi+rax  ],       mm1

    ; begin epilog
    pop         rdi
    pop         rsi
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_intra_pred_uv_dc128_mmx(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
global sym(vp8_intra_pred_uv_dc128_mmx) PRIVATE
sym(vp8_intra_pred_uv_dc128_mmx):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    GET_GOT     rbx
    ; end prolog

    ;arg(2), arg(3), arg(4) not used

    ; write out
    movq        mm1,        [GLOBAL(dc_128)]
    mov         rax,        arg(0) ;dst;
    movsxd      rdx,        dword ptr arg(1) ;dst_stride
    lea         rcx,        [rdx*3]

    movq [rax      ],       mm1
    movq [rax+rdx  ],       mm1
    movq [rax+rdx*2],       mm1
    movq [rax+rcx  ],       mm1
    lea         rax,        [rax+rdx*4]
    movq [rax      ],       mm1
    movq [rax+rdx  ],       mm1
    movq [rax+rdx*2],       mm1
    movq [rax+rcx  ],       mm1

    ; begin epilog
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_intra_pred_uv_tm_sse2(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
%macro vp8_intra_pred_uv_tm 1
global sym(vp8_intra_pred_uv_tm_%1) PRIVATE
sym(vp8_intra_pred_uv_tm_%1):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    GET_GOT     rbx
    push        rsi
    push        rdi
    push        rbx
    ; end prolog

    ; read top row
    mov         edx,        4
    mov         rsi,        arg(2) ;above
    movsxd      rax,        dword ptr arg(4) ;left_stride;
    pxor        xmm0,       xmm0
%ifidn %1, ssse3
    movdqa      xmm2,       [GLOBAL(dc_1024)]
%endif
    movq        xmm1,       [rsi]
    punpcklbw   xmm1,       xmm0

    ; set up left ptrs ans subtract topleft
    movd        xmm3,       [rsi-1]
    mov         rsi,        arg(3) ;left;
%ifidn %1, sse2
    punpcklbw   xmm3,       xmm0
    pshuflw     xmm3,       xmm3, 0x0
    punpcklqdq  xmm3,       xmm3
%else
    pshufb      xmm3,       xmm2
%endif
    psubw       xmm1,       xmm3

    ; set up dest ptrs
    mov         rdi,        arg(0) ;dst;
    movsxd      rcx,        dword ptr arg(1) ;dst_stride

.vp8_intra_pred_uv_tm_%1_loop:
    mov         bl,         [rsi]
    movd        xmm3,       ebx

    mov         bl,         [rsi+rax]
    movd        xmm5,       ebx
%ifidn %1, sse2
    punpcklbw   xmm3,       xmm0
    punpcklbw   xmm5,       xmm0
    pshuflw     xmm3,       xmm3, 0x0
    pshuflw     xmm5,       xmm5, 0x0
    punpcklqdq  xmm3,       xmm3
    punpcklqdq  xmm5,       xmm5
%else
    pshufb      xmm3,       xmm2
    pshufb      xmm5,       xmm2
%endif
    paddw       xmm3,       xmm1
    paddw       xmm5,       xmm1
    packuswb    xmm3,       xmm5
    movq  [rdi    ],        xmm3
    movhps[rdi+rcx],        xmm3
    lea         rsi,        [rsi+rax*2]
    lea         rdi,        [rdi+rcx*2]
    dec         edx
    jnz .vp8_intra_pred_uv_tm_%1_loop

    ; begin epilog
    pop         rbx
    pop         rdi
    pop         rsi
    RESTORE_GOT
    UNSHADOW_ARGS
    pop         rbp
    ret
%endmacro

vp8_intra_pred_uv_tm sse2
vp8_intra_pred_uv_tm ssse3

;void vp8_intra_pred_uv_ve_mmx(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride,
;    )
global sym(vp8_intra_pred_uv_ve_mmx) PRIVATE
sym(vp8_intra_pred_uv_ve_mmx):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    ; end prolog

    ; arg(3), arg(4) not used

    ; read from top
    mov         rax,        arg(2) ;src;

    movq        mm1,        [rax]

    ; write out
    mov         rax,        arg(0) ;dst;
    movsxd      rdx,        dword ptr arg(1) ;dst_stride
    lea         rcx,        [rdx*3]

    movq [rax      ],       mm1
    movq [rax+rdx  ],       mm1
    movq [rax+rdx*2],       mm1
    movq [rax+rcx  ],       mm1
    lea         rax,        [rax+rdx*4]
    movq [rax      ],       mm1
    movq [rax+rdx  ],       mm1
    movq [rax+rdx*2],       mm1
    movq [rax+rcx  ],       mm1

    ; begin epilog
    UNSHADOW_ARGS
    pop         rbp
    ret

;void vp8_intra_pred_uv_ho_mmx2(
;    unsigned char *dst,
;    int dst_stride
;    unsigned char *above,
;    unsigned char *left,
;    int left_stride
;    )
%macro vp8_intra_pred_uv_ho 1
global sym(vp8_intra_pred_uv_ho_%1) PRIVATE
sym(vp8_intra_pred_uv_ho_%1):
    push        rbp
    mov         rbp, rsp
    SHADOW_ARGS_TO_STACK 5
    push        rsi
    push        rdi
    push        rbx
%ifidn %1, ssse3
    GET_GOT     rbx
%endif
    ; end prolog

    ;arg(2) not used

    ; read from left and write out
%ifidn %1, mmx2
    mov         edx,        4
%endif
    mov         rsi,        arg(3) ;left
    movsxd      rax,        dword ptr arg(4) ;left_stride;
    mov         rdi,        arg(0) ;dst;
    movsxd      rcx,        dword ptr arg(1) ;dst_stride
%ifidn %1, ssse3
    lea         rdx,        [rcx*3]
    movdqa      xmm2,       [GLOBAL(dc_00001111)]
%endif

%ifidn %1, mmx2
.vp8_intra_pred_uv_ho_%1_loop:
    mov         bl,         [rsi]
    movd        mm0,        ebx

    mov         bl,         [rsi+rax]
    movd        mm1,        ebx

    punpcklbw   mm0,        mm0
    punpcklbw   mm1,        mm1
    pshufw      mm0,        mm0, 0x0
    pshufw      mm1,        mm1, 0x0
    movq  [rdi    ],        mm0
    movq  [rdi+rcx],        mm1
    lea         rsi,        [rsi+rax*2]
    lea         rdi,        [rdi+rcx*2]
    dec         edx
    jnz .vp8_intra_pred_uv_ho_%1_loop
%else
    mov         bl,         [rsi]
    movd        xmm0,       ebx

    mov         bl,         [rsi+rax]
    movd        xmm3,       ebx

    mov         bl,         [rsi+rax*2]
    movd        xmm1,       ebx

    lea         rbx,        [rax*3]
    mov         bl,         [rsi+rbx]
    movd        xmm4,       ebx

    punpcklbw   xmm0,       xmm3
    punpcklbw   xmm1,       xmm4
    pshufb      xmm0,       xmm2
    pshufb      xmm1,       xmm2
    movq   [rdi    ],       xmm0
    movhps [rdi+rcx],       xmm0
    movq [rdi+rcx*2],       xmm1
    movhps [rdi+rdx],       xmm1
    lea         rsi,        [rsi+rax*4]
    lea         rdi,        [rdi+rcx*4]

    mov         bl,         [rsi]
    movd        xmm0,       ebx

    mov         bl,         [rsi+rax]
    movd        xmm3,       ebx

    mov         bl,         [rsi+rax*2]
    movd        xmm1,       ebx

    lea         rbx,        [rax*3]
    mov         bl,         [rsi+rbx]
    movd        xmm4,       ebx

    punpcklbw   xmm0,       xmm3
    punpcklbw   xmm1,       xmm4
    pshufb      xmm0,       xmm2
    pshufb      xmm1,       xmm2
    movq   [rdi    ],       xmm0
    movhps [rdi+rcx],       xmm0
    movq [rdi+rcx*2],       xmm1
    movhps [rdi+rdx],       xmm1
%endif

    ; begin epilog
%ifidn %1, ssse3
    RESTORE_GOT
%endif
    pop         rbx
    pop         rdi
    pop         rsi
    UNSHADOW_ARGS
    pop         rbp
    ret
%endmacro

vp8_intra_pred_uv_ho mmx2
vp8_intra_pred_uv_ho ssse3

SECTION_RODATA
align 16
dc_128:
    times 8 db 128
dc_4:
    times 4 dw 4
align 16
dc_1024:
    times 8 dw 0x400
align 16
dc_00001111:
    times 8 db 0
    times 8 db 1


kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	dac78793          	addi	a5,a5,-596 # 80005e10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	59e080e7          	jalr	1438(ra) # 800026ca <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	038080e7          	jalr	56(ra) # 8000220c <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	464080e7          	jalr	1124(ra) # 80002674 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	42e080e7          	jalr	1070(ra) # 80002720 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f5c080e7          	jalr	-164(ra) # 800023a2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b02080e7          	jalr	-1278(ra) # 800023a2 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	8e0080e7          	jalr	-1824(ra) # 8000220c <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	98c080e7          	jalr	-1652(ra) # 80002860 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f74080e7          	jalr	-140(ra) # 80005e50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	176080e7          	jalr	374(ra) # 8000205a <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	8ec080e7          	jalr	-1812(ra) # 80002838 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	90c080e7          	jalr	-1780(ra) # 80002860 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	ede080e7          	jalr	-290(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	eec080e7          	jalr	-276(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0d2080e7          	jalr	210(ra) # 8000303e <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	762080e7          	jalr	1890(ra) # 800036d6 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	70c080e7          	jalr	1804(ra) # 80004688 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	fee080e7          	jalr	-18(ra) # 80005f72 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e407a783          	lw	a5,-448(a5) # 80008840 <first.1704>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e6e080e7          	jalr	-402(ra) # 80002878 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e207a323          	sw	zero,-474(a5) # 80008840 <first.1704>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	c32080e7          	jalr	-974(ra) # 80003656 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	df878793          	addi	a5,a5,-520 # 80008844 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	ba858593          	addi	a1,a1,-1112 # 80008850 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	39e080e7          	jalr	926(ra) # 80004084 <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00003097          	auipc	ra,0x3
    80001e20:	8fe080e7          	jalr	-1794(ra) # 8000471a <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	a52080e7          	jalr	-1454(ra) # 80003890 <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <clone>:
{	
    80001eba:	711d                	addi	sp,sp,-96
    80001ebc:	ec86                	sd	ra,88(sp)
    80001ebe:	e8a2                	sd	s0,80(sp)
    80001ec0:	e4a6                	sd	s1,72(sp)
    80001ec2:	e0ca                	sd	s2,64(sp)
    80001ec4:	fc4e                	sd	s3,56(sp)
    80001ec6:	f852                	sd	s4,48(sp)
    80001ec8:	f456                	sd	s5,40(sp)
    80001eca:	f05a                	sd	s6,32(sp)
    80001ecc:	ec5e                	sd	s7,24(sp)
    80001ece:	1080                	addi	s0,sp,96
    80001ed0:	8a2a                	mv	s4,a0
    80001ed2:	8b2e                	mv	s6,a1
    80001ed4:	84b2                	mv	s1,a2
    80001ed6:	8ab6                	mv	s5,a3
	struct proc *p = myproc();
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	ad8080e7          	jalr	-1320(ra) # 800019b0 <myproc>
    80001ee0:	89aa                	mv	s3,a0
	if((np = allocproc()) == 0){
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	cd8080e7          	jalr	-808(ra) # 80001bba <allocproc>
    80001eea:	16050263          	beqz	a0,8000204e <clone+0x194>
    80001eee:	892a                	mv	s2,a0
	if((uint64)stack%PGSIZE != 0 || stack == 0) {
    80001ef0:	034a1793          	slli	a5,s4,0x34
    80001ef4:	14079f63          	bnez	a5,80002052 <clone+0x198>
    80001ef8:	140a0f63          	beqz	s4,80002056 <clone+0x19c>
	np->state = UNUSED;
    80001efc:	00052c23          	sw	zero,24(a0)
	np->sz = p->sz;
    80001f00:	0489b783          	ld	a5,72(s3)
    80001f04:	e53c                	sd	a5,72(a0)
	*(np->trapframe) = *(p->trapframe);
    80001f06:	0589b683          	ld	a3,88(s3)
    80001f0a:	87b6                	mv	a5,a3
    80001f0c:	6d38                	ld	a4,88(a0)
    80001f0e:	12068693          	addi	a3,a3,288
    80001f12:	0007b803          	ld	a6,0(a5)
    80001f16:	6788                	ld	a0,8(a5)
    80001f18:	6b90                	ld	a2,16(a5)
    80001f1a:	6f8c                	ld	a1,24(a5)
    80001f1c:	01073023          	sd	a6,0(a4)
    80001f20:	e708                	sd	a0,8(a4)
    80001f22:	eb10                	sd	a2,16(a4)
    80001f24:	ef0c                	sd	a1,24(a4)
    80001f26:	02078793          	addi	a5,a5,32
    80001f2a:	02070713          	addi	a4,a4,32
    80001f2e:	fed792e3          	bne	a5,a3,80001f12 <clone+0x58>
	np->pagetable = p->pagetable;
    80001f32:	0509b783          	ld	a5,80(s3)
    80001f36:	04f93823          	sd	a5,80(s2)
	np->context.ra = (uint64)func;
    80001f3a:	06993023          	sd	s1,96(s2)
	np->trapframe->a0 = 0;
    80001f3e:	05893783          	ld	a5,88(s2)
    80001f42:	0607b823          	sd	zero,112(a5)
    80001f46:	0d000493          	li	s1,208
	for(i=0;i<NOFILE;i++)
    80001f4a:	15000b93          	li	s7,336
    80001f4e:	a01d                	j	80001f74 <clone+0xba>
			np->ofile[i] = filedup(p->ofile[i]);
    80001f50:	00002097          	auipc	ra,0x2
    80001f54:	7ca080e7          	jalr	1994(ra) # 8000471a <filedup>
    80001f58:	009907b3          	add	a5,s2,s1
    80001f5c:	e388                	sd	a0,0(a5)
		np->cwd = idup(p->cwd);
    80001f5e:	1509b503          	ld	a0,336(s3)
    80001f62:	00002097          	auipc	ra,0x2
    80001f66:	92e080e7          	jalr	-1746(ra) # 80003890 <idup>
    80001f6a:	14a93823          	sd	a0,336(s2)
	for(i=0;i<NOFILE;i++)
    80001f6e:	04a1                	addi	s1,s1,8
    80001f70:	01748763          	beq	s1,s7,80001f7e <clone+0xc4>
		if(p->ofile[i])
    80001f74:	009987b3          	add	a5,s3,s1
    80001f78:	6388                	ld	a0,0(a5)
    80001f7a:	f979                	bnez	a0,80001f50 <clone+0x96>
    80001f7c:	b7cd                	j	80001f5e <clone+0xa4>
	safestrcpy(np->name,p->name,sizeof(p->name));
    80001f7e:	4641                	li	a2,16
    80001f80:	15898593          	addi	a1,s3,344
    80001f84:	15890513          	addi	a0,s2,344
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	eaa080e7          	jalr	-342(ra) # 80000e32 <safestrcpy>
	ustack[0] = 0xffffffff;
    80001f90:	57fd                	li	a5,-1
    80001f92:	9381                	srli	a5,a5,0x20
    80001f94:	faf43023          	sd	a5,-96(s0)
	ustack[1] = (uint64)arg;
    80001f98:	fb543423          	sd	s5,-88(s0)
	np->context.sp = (uint64)(stack+PGSIZE-4);
    80001f9c:	6685                	lui	a3,0x1
    80001f9e:	ffc68713          	addi	a4,a3,-4 # ffc <_entry-0x7ffff004>
    80001fa2:	9752                	add	a4,a4,s4
    80001fa4:	06e93423          	sd	a4,104(s2)
	*((uint64*)(np->context.sp)) = (uint64)arg;
    80001fa8:	9a36                	add	s4,s4,a3
    80001faa:	ff5a3e23          	sd	s5,-4(s4)
	*((uint64*)(np->context.sp)-4) = 0xFFFFFFFF;
    80001fae:	06893703          	ld	a4,104(s2)
    80001fb2:	fef73023          	sd	a5,-32(a4)
	np->context.sp = (np->context.sp) - 4;
    80001fb6:	06893583          	ld	a1,104(s2)
    80001fba:	15f1                	addi	a1,a1,-4
    80001fbc:	06b93423          	sd	a1,104(s2)
	if(copyout(np->pagetable,np->context.sp,(char*)ustack,size)<0)
    80001fc0:	86da                	mv	a3,s6
    80001fc2:	fa040613          	addi	a2,s0,-96
    80001fc6:	05093503          	ld	a0,80(s2)
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	6a8080e7          	jalr	1704(ra) # 80001672 <copyout>
    80001fd2:	06054463          	bltz	a0,8000203a <clone+0x180>
	np->state = RUNNABLE;
    80001fd6:	448d                	li	s1,3
    80001fd8:	00992c23          	sw	s1,24(s2)
	pid = np->pid;
    80001fdc:	03092a83          	lw	s5,48(s2)
	release(&np->lock);
    80001fe0:	854a                	mv	a0,s2
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
	acquire(&wait_lock);
    80001fea:	0000fa17          	auipc	s4,0xf
    80001fee:	2cea0a13          	addi	s4,s4,718 # 800112b8 <wait_lock>
    80001ff2:	8552                	mv	a0,s4
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	bf0080e7          	jalr	-1040(ra) # 80000be4 <acquire>
	np->parent = p;
    80001ffc:	03393c23          	sd	s3,56(s2)
	release(&wait_lock);
    80002000:	8552                	mv	a0,s4
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	c96080e7          	jalr	-874(ra) # 80000c98 <release>
	acquire(&np->lock);
    8000200a:	854a                	mv	a0,s2
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	bd8080e7          	jalr	-1064(ra) # 80000be4 <acquire>
	np->state = RUNNABLE;
    80002014:	00992c23          	sw	s1,24(s2)
	release(&np->lock);
    80002018:	854a                	mv	a0,s2
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	c7e080e7          	jalr	-898(ra) # 80000c98 <release>
}
    80002022:	8556                	mv	a0,s5
    80002024:	60e6                	ld	ra,88(sp)
    80002026:	6446                	ld	s0,80(sp)
    80002028:	64a6                	ld	s1,72(sp)
    8000202a:	6906                	ld	s2,64(sp)
    8000202c:	79e2                	ld	s3,56(sp)
    8000202e:	7a42                	ld	s4,48(sp)
    80002030:	7aa2                	ld	s5,40(sp)
    80002032:	7b02                	ld	s6,32(sp)
    80002034:	6be2                	ld	s7,24(sp)
    80002036:	6125                	addi	sp,sp,96
    80002038:	8082                	ret
		printf("Stack copy failed\n");
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1de50513          	addi	a0,a0,478 # 80008218 <digits+0x1d8>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	546080e7          	jalr	1350(ra) # 80000588 <printf>
		return -1;
    8000204a:	5afd                	li	s5,-1
    8000204c:	bfd9                	j	80002022 <clone+0x168>
		return -1;
    8000204e:	5afd                	li	s5,-1
    80002050:	bfc9                	j	80002022 <clone+0x168>
		return -1;
    80002052:	5afd                	li	s5,-1
    80002054:	b7f9                	j	80002022 <clone+0x168>
    80002056:	5afd                	li	s5,-1
    80002058:	b7e9                	j	80002022 <clone+0x168>

000000008000205a <scheduler>:
{
    8000205a:	7139                	addi	sp,sp,-64
    8000205c:	fc06                	sd	ra,56(sp)
    8000205e:	f822                	sd	s0,48(sp)
    80002060:	f426                	sd	s1,40(sp)
    80002062:	f04a                	sd	s2,32(sp)
    80002064:	ec4e                	sd	s3,24(sp)
    80002066:	e852                	sd	s4,16(sp)
    80002068:	e456                	sd	s5,8(sp)
    8000206a:	e05a                	sd	s6,0(sp)
    8000206c:	0080                	addi	s0,sp,64
    8000206e:	8792                	mv	a5,tp
  int id = r_tp();
    80002070:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002072:	00779a93          	slli	s5,a5,0x7
    80002076:	0000f717          	auipc	a4,0xf
    8000207a:	22a70713          	addi	a4,a4,554 # 800112a0 <pid_lock>
    8000207e:	9756                	add	a4,a4,s5
    80002080:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002084:	0000f717          	auipc	a4,0xf
    80002088:	25470713          	addi	a4,a4,596 # 800112d8 <cpus+0x8>
    8000208c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000208e:	498d                	li	s3,3
        p->state = RUNNING;
    80002090:	4b11                	li	s6,4
        c->proc = p;
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	0000fa17          	auipc	s4,0xf
    80002098:	20ca0a13          	addi	s4,s4,524 # 800112a0 <pid_lock>
    8000209c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000209e:	00015917          	auipc	s2,0x15
    800020a2:	03290913          	addi	s2,s2,50 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020aa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ae:	10079073          	csrw	sstatus,a5
    800020b2:	0000f497          	auipc	s1,0xf
    800020b6:	61e48493          	addi	s1,s1,1566 # 800116d0 <proc>
    800020ba:	a03d                	j	800020e8 <scheduler+0x8e>
        p->state = RUNNING;
    800020bc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020c0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020c4:	06048593          	addi	a1,s1,96
    800020c8:	8556                	mv	a0,s5
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	704080e7          	jalr	1796(ra) # 800027ce <swtch>
        c->proc = 0;
    800020d2:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e0:	16848493          	addi	s1,s1,360
    800020e4:	fd2481e3          	beq	s1,s2,800020a6 <scheduler+0x4c>
      acquire(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	afa080e7          	jalr	-1286(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    800020f2:	4c9c                	lw	a5,24(s1)
    800020f4:	ff3791e3          	bne	a5,s3,800020d6 <scheduler+0x7c>
    800020f8:	b7d1                	j	800020bc <scheduler+0x62>

00000000800020fa <sched>:
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	8a8080e7          	jalr	-1880(ra) # 800019b0 <myproc>
    80002110:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	a58080e7          	jalr	-1448(ra) # 80000b6a <holding>
    8000211a:	c93d                	beqz	a0,80002190 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000211c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000211e:	2781                	sext.w	a5,a5
    80002120:	079e                	slli	a5,a5,0x7
    80002122:	0000f717          	auipc	a4,0xf
    80002126:	17e70713          	addi	a4,a4,382 # 800112a0 <pid_lock>
    8000212a:	97ba                	add	a5,a5,a4
    8000212c:	0a87a703          	lw	a4,168(a5)
    80002130:	4785                	li	a5,1
    80002132:	06f71763          	bne	a4,a5,800021a0 <sched+0xa6>
  if(p->state == RUNNING)
    80002136:	4c98                	lw	a4,24(s1)
    80002138:	4791                	li	a5,4
    8000213a:	06f70b63          	beq	a4,a5,800021b0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000213e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002142:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002144:	efb5                	bnez	a5,800021c0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002146:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002148:	0000f917          	auipc	s2,0xf
    8000214c:	15890913          	addi	s2,s2,344 # 800112a0 <pid_lock>
    80002150:	2781                	sext.w	a5,a5
    80002152:	079e                	slli	a5,a5,0x7
    80002154:	97ca                	add	a5,a5,s2
    80002156:	0ac7a983          	lw	s3,172(a5)
    8000215a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000215c:	2781                	sext.w	a5,a5
    8000215e:	079e                	slli	a5,a5,0x7
    80002160:	0000f597          	auipc	a1,0xf
    80002164:	17858593          	addi	a1,a1,376 # 800112d8 <cpus+0x8>
    80002168:	95be                	add	a1,a1,a5
    8000216a:	06048513          	addi	a0,s1,96
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	660080e7          	jalr	1632(ra) # 800027ce <swtch>
    80002176:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002178:	2781                	sext.w	a5,a5
    8000217a:	079e                	slli	a5,a5,0x7
    8000217c:	97ca                	add	a5,a5,s2
    8000217e:	0b37a623          	sw	s3,172(a5)
}
    80002182:	70a2                	ld	ra,40(sp)
    80002184:	7402                	ld	s0,32(sp)
    80002186:	64e2                	ld	s1,24(sp)
    80002188:	6942                	ld	s2,16(sp)
    8000218a:	69a2                	ld	s3,8(sp)
    8000218c:	6145                	addi	sp,sp,48
    8000218e:	8082                	ret
    panic("sched p->lock");
    80002190:	00006517          	auipc	a0,0x6
    80002194:	0a050513          	addi	a0,a0,160 # 80008230 <digits+0x1f0>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
    panic("sched locks");
    800021a0:	00006517          	auipc	a0,0x6
    800021a4:	0a050513          	addi	a0,a0,160 # 80008240 <digits+0x200>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	396080e7          	jalr	918(ra) # 8000053e <panic>
    panic("sched running");
    800021b0:	00006517          	auipc	a0,0x6
    800021b4:	0a050513          	addi	a0,a0,160 # 80008250 <digits+0x210>
    800021b8:	ffffe097          	auipc	ra,0xffffe
    800021bc:	386080e7          	jalr	902(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021c0:	00006517          	auipc	a0,0x6
    800021c4:	0a050513          	addi	a0,a0,160 # 80008260 <digits+0x220>
    800021c8:	ffffe097          	auipc	ra,0xffffe
    800021cc:	376080e7          	jalr	886(ra) # 8000053e <panic>

00000000800021d0 <yield>:
{
    800021d0:	1101                	addi	sp,sp,-32
    800021d2:	ec06                	sd	ra,24(sp)
    800021d4:	e822                	sd	s0,16(sp)
    800021d6:	e426                	sd	s1,8(sp)
    800021d8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	7d6080e7          	jalr	2006(ra) # 800019b0 <myproc>
    800021e2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	a00080e7          	jalr	-1536(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021ec:	478d                	li	a5,3
    800021ee:	cc9c                	sw	a5,24(s1)
  sched();
    800021f0:	00000097          	auipc	ra,0x0
    800021f4:	f0a080e7          	jalr	-246(ra) # 800020fa <sched>
  release(&p->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a9e080e7          	jalr	-1378(ra) # 80000c98 <release>
}
    80002202:	60e2                	ld	ra,24(sp)
    80002204:	6442                	ld	s0,16(sp)
    80002206:	64a2                	ld	s1,8(sp)
    80002208:	6105                	addi	sp,sp,32
    8000220a:	8082                	ret

000000008000220c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000220c:	7179                	addi	sp,sp,-48
    8000220e:	f406                	sd	ra,40(sp)
    80002210:	f022                	sd	s0,32(sp)
    80002212:	ec26                	sd	s1,24(sp)
    80002214:	e84a                	sd	s2,16(sp)
    80002216:	e44e                	sd	s3,8(sp)
    80002218:	1800                	addi	s0,sp,48
    8000221a:	89aa                	mv	s3,a0
    8000221c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	792080e7          	jalr	1938(ra) # 800019b0 <myproc>
    80002226:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
  release(lk);
    80002230:	854a                	mv	a0,s2
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a66080e7          	jalr	-1434(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000223a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000223e:	4789                	li	a5,2
    80002240:	cc9c                	sw	a5,24(s1)

  sched();
    80002242:	00000097          	auipc	ra,0x0
    80002246:	eb8080e7          	jalr	-328(ra) # 800020fa <sched>

  // Tidy up.
  p->chan = 0;
    8000224a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
  acquire(lk);
    80002258:	854a                	mv	a0,s2
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
}
    80002262:	70a2                	ld	ra,40(sp)
    80002264:	7402                	ld	s0,32(sp)
    80002266:	64e2                	ld	s1,24(sp)
    80002268:	6942                	ld	s2,16(sp)
    8000226a:	69a2                	ld	s3,8(sp)
    8000226c:	6145                	addi	sp,sp,48
    8000226e:	8082                	ret

0000000080002270 <wait>:
{
    80002270:	715d                	addi	sp,sp,-80
    80002272:	e486                	sd	ra,72(sp)
    80002274:	e0a2                	sd	s0,64(sp)
    80002276:	fc26                	sd	s1,56(sp)
    80002278:	f84a                	sd	s2,48(sp)
    8000227a:	f44e                	sd	s3,40(sp)
    8000227c:	f052                	sd	s4,32(sp)
    8000227e:	ec56                	sd	s5,24(sp)
    80002280:	e85a                	sd	s6,16(sp)
    80002282:	e45e                	sd	s7,8(sp)
    80002284:	e062                	sd	s8,0(sp)
    80002286:	0880                	addi	s0,sp,80
    80002288:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	726080e7          	jalr	1830(ra) # 800019b0 <myproc>
    80002292:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002294:	0000f517          	auipc	a0,0xf
    80002298:	02450513          	addi	a0,a0,36 # 800112b8 <wait_lock>
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	948080e7          	jalr	-1720(ra) # 80000be4 <acquire>
    havekids = 0;
    800022a4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022a8:	00015997          	auipc	s3,0x15
    800022ac:	e2898993          	addi	s3,s3,-472 # 800170d0 <tickslock>
        havekids = 1;
    800022b0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022b2:	0000fc17          	auipc	s8,0xf
    800022b6:	006c0c13          	addi	s8,s8,6 # 800112b8 <wait_lock>
    havekids = 0;
    800022ba:	86de                	mv	a3,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022bc:	0000f497          	auipc	s1,0xf
    800022c0:	41448493          	addi	s1,s1,1044 # 800116d0 <proc>
    800022c4:	a01d                	j	800022ea <wait+0x7a>
        acquire(&np->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	91c080e7          	jalr	-1764(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022d0:	4c9c                	lw	a5,24(s1)
    800022d2:	03478563          	beq	a5,s4,800022fc <wait+0x8c>
        release(&np->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
        havekids = 1;
    800022e0:	86d6                	mv	a3,s5
    for(np = proc; np < &proc[NPROC]; np++){
    800022e2:	16848493          	addi	s1,s1,360
    800022e6:	09348963          	beq	s1,s3,80002378 <wait+0x108>
      if(np->parent == p || np->pagetable != p->pagetable){
    800022ea:	7c9c                	ld	a5,56(s1)
    800022ec:	fd278de3          	beq	a5,s2,800022c6 <wait+0x56>
    800022f0:	68b8                	ld	a4,80(s1)
    800022f2:	05093783          	ld	a5,80(s2)
    800022f6:	fcf718e3          	bne	a4,a5,800022c6 <wait+0x56>
    800022fa:	b7e5                	j	800022e2 <wait+0x72>
          pid = np->pid;
    800022fc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002300:	000b0e63          	beqz	s6,8000231c <wait+0xac>
    80002304:	4691                	li	a3,4
    80002306:	02c48613          	addi	a2,s1,44
    8000230a:	85da                	mv	a1,s6
    8000230c:	05093503          	ld	a0,80(s2)
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	362080e7          	jalr	866(ra) # 80001672 <copyout>
    80002318:	04054163          	bltz	a0,8000235a <wait+0xea>
          freeproc(np);
    8000231c:	8526                	mv	a0,s1
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	844080e7          	jalr	-1980(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
          release(&wait_lock);
    80002330:	0000f517          	auipc	a0,0xf
    80002334:	f8850513          	addi	a0,a0,-120 # 800112b8 <wait_lock>
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	960080e7          	jalr	-1696(ra) # 80000c98 <release>
}
    80002340:	854e                	mv	a0,s3
    80002342:	60a6                	ld	ra,72(sp)
    80002344:	6406                	ld	s0,64(sp)
    80002346:	74e2                	ld	s1,56(sp)
    80002348:	7942                	ld	s2,48(sp)
    8000234a:	79a2                	ld	s3,40(sp)
    8000234c:	7a02                	ld	s4,32(sp)
    8000234e:	6ae2                	ld	s5,24(sp)
    80002350:	6b42                	ld	s6,16(sp)
    80002352:	6ba2                	ld	s7,8(sp)
    80002354:	6c02                	ld	s8,0(sp)
    80002356:	6161                	addi	sp,sp,80
    80002358:	8082                	ret
            release(&np->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	93c080e7          	jalr	-1732(ra) # 80000c98 <release>
            release(&wait_lock);
    80002364:	0000f517          	auipc	a0,0xf
    80002368:	f5450513          	addi	a0,a0,-172 # 800112b8 <wait_lock>
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
            return -1;
    80002374:	59fd                	li	s3,-1
    80002376:	b7e9                	j	80002340 <wait+0xd0>
    if(!havekids || p->killed){
    80002378:	c681                	beqz	a3,80002380 <wait+0x110>
    8000237a:	02892783          	lw	a5,40(s2)
    8000237e:	cb99                	beqz	a5,80002394 <wait+0x124>
      release(&wait_lock);
    80002380:	0000f517          	auipc	a0,0xf
    80002384:	f3850513          	addi	a0,a0,-200 # 800112b8 <wait_lock>
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
      return -1;
    80002390:	59fd                	li	s3,-1
    80002392:	b77d                	j	80002340 <wait+0xd0>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002394:	85e2                	mv	a1,s8
    80002396:	854a                	mv	a0,s2
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	e74080e7          	jalr	-396(ra) # 8000220c <sleep>
    havekids = 0;
    800023a0:	bf29                	j	800022ba <wait+0x4a>

00000000800023a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023a2:	7139                	addi	sp,sp,-64
    800023a4:	fc06                	sd	ra,56(sp)
    800023a6:	f822                	sd	s0,48(sp)
    800023a8:	f426                	sd	s1,40(sp)
    800023aa:	f04a                	sd	s2,32(sp)
    800023ac:	ec4e                	sd	s3,24(sp)
    800023ae:	e852                	sd	s4,16(sp)
    800023b0:	e456                	sd	s5,8(sp)
    800023b2:	0080                	addi	s0,sp,64
    800023b4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023b6:	0000f497          	auipc	s1,0xf
    800023ba:	31a48493          	addi	s1,s1,794 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023be:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023c0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c2:	00015917          	auipc	s2,0x15
    800023c6:	d0e90913          	addi	s2,s2,-754 # 800170d0 <tickslock>
    800023ca:	a821                	j	800023e2 <wakeup+0x40>
        p->state = RUNNABLE;
    800023cc:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023da:	16848493          	addi	s1,s1,360
    800023de:	03248463          	beq	s1,s2,80002406 <wakeup+0x64>
    if(p != myproc()){
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	5ce080e7          	jalr	1486(ra) # 800019b0 <myproc>
    800023ea:	fea488e3          	beq	s1,a0,800023da <wakeup+0x38>
      acquire(&p->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023f8:	4c9c                	lw	a5,24(s1)
    800023fa:	fd379be3          	bne	a5,s3,800023d0 <wakeup+0x2e>
    800023fe:	709c                	ld	a5,32(s1)
    80002400:	fd4798e3          	bne	a5,s4,800023d0 <wakeup+0x2e>
    80002404:	b7e1                	j	800023cc <wakeup+0x2a>
    }
  }
}
    80002406:	70e2                	ld	ra,56(sp)
    80002408:	7442                	ld	s0,48(sp)
    8000240a:	74a2                	ld	s1,40(sp)
    8000240c:	7902                	ld	s2,32(sp)
    8000240e:	69e2                	ld	s3,24(sp)
    80002410:	6a42                	ld	s4,16(sp)
    80002412:	6aa2                	ld	s5,8(sp)
    80002414:	6121                	addi	sp,sp,64
    80002416:	8082                	ret

0000000080002418 <reparent>:
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	2a648493          	addi	s1,s1,678 # 800116d0 <proc>
      pp->parent = initproc;
    80002432:	00007a17          	auipc	s4,0x7
    80002436:	bf6a0a13          	addi	s4,s4,-1034 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000243a:	00015997          	auipc	s3,0x15
    8000243e:	c9698993          	addi	s3,s3,-874 # 800170d0 <tickslock>
    80002442:	a029                	j	8000244c <reparent+0x34>
    80002444:	16848493          	addi	s1,s1,360
    80002448:	01348d63          	beq	s1,s3,80002462 <reparent+0x4a>
    if(pp->parent == p){
    8000244c:	7c9c                	ld	a5,56(s1)
    8000244e:	ff279be3          	bne	a5,s2,80002444 <reparent+0x2c>
      pp->parent = initproc;
    80002452:	000a3503          	ld	a0,0(s4)
    80002456:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	f4a080e7          	jalr	-182(ra) # 800023a2 <wakeup>
    80002460:	b7d5                	j	80002444 <reparent+0x2c>
}
    80002462:	70a2                	ld	ra,40(sp)
    80002464:	7402                	ld	s0,32(sp)
    80002466:	64e2                	ld	s1,24(sp)
    80002468:	6942                	ld	s2,16(sp)
    8000246a:	69a2                	ld	s3,8(sp)
    8000246c:	6a02                	ld	s4,0(sp)
    8000246e:	6145                	addi	sp,sp,48
    80002470:	8082                	ret

0000000080002472 <exit>:
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	52c080e7          	jalr	1324(ra) # 800019b0 <myproc>
    8000248c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000248e:	00007797          	auipc	a5,0x7
    80002492:	b9a7b783          	ld	a5,-1126(a5) # 80009028 <initproc>
    80002496:	0d050493          	addi	s1,a0,208
    8000249a:	15050913          	addi	s2,a0,336
    8000249e:	02a79363          	bne	a5,a0,800024c4 <exit+0x52>
    panic("init exiting");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	dd650513          	addi	a0,a0,-554 # 80008278 <digits+0x238>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
      fileclose(f);
    800024b2:	00002097          	auipc	ra,0x2
    800024b6:	2ba080e7          	jalr	698(ra) # 8000476c <fileclose>
      p->ofile[fd] = 0;
    800024ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024be:	04a1                	addi	s1,s1,8
    800024c0:	01248563          	beq	s1,s2,800024ca <exit+0x58>
    if(p->ofile[fd]){
    800024c4:	6088                	ld	a0,0(s1)
    800024c6:	f575                	bnez	a0,800024b2 <exit+0x40>
    800024c8:	bfdd                	j	800024be <exit+0x4c>
  begin_op();
    800024ca:	00002097          	auipc	ra,0x2
    800024ce:	dd6080e7          	jalr	-554(ra) # 800042a0 <begin_op>
  iput(p->cwd);
    800024d2:	1509b503          	ld	a0,336(s3)
    800024d6:	00001097          	auipc	ra,0x1
    800024da:	5b2080e7          	jalr	1458(ra) # 80003a88 <iput>
  end_op();
    800024de:	00002097          	auipc	ra,0x2
    800024e2:	e42080e7          	jalr	-446(ra) # 80004320 <end_op>
  p->cwd = 0;
    800024e6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024ea:	0000f497          	auipc	s1,0xf
    800024ee:	dce48493          	addi	s1,s1,-562 # 800112b8 <wait_lock>
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	6f0080e7          	jalr	1776(ra) # 80000be4 <acquire>
  reparent(p);
    800024fc:	854e                	mv	a0,s3
    800024fe:	00000097          	auipc	ra,0x0
    80002502:	f1a080e7          	jalr	-230(ra) # 80002418 <reparent>
  wakeup(p->parent);
    80002506:	0389b503          	ld	a0,56(s3)
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	e98080e7          	jalr	-360(ra) # 800023a2 <wakeup>
  acquire(&p->lock);
    80002512:	854e                	mv	a0,s3
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6d0080e7          	jalr	1744(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000251c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002520:	4795                	li	a5,5
    80002522:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	770080e7          	jalr	1904(ra) # 80000c98 <release>
  sched();
    80002530:	00000097          	auipc	ra,0x0
    80002534:	bca080e7          	jalr	-1078(ra) # 800020fa <sched>
  panic("zombie exit");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	d5050513          	addi	a0,a0,-688 # 80008288 <digits+0x248>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>

0000000080002548 <texit>:
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	45a080e7          	jalr	1114(ra) # 800019b0 <myproc>
    8000255e:	89aa                	mv	s3,a0
	if(p == initproc)
    80002560:	00007797          	auipc	a5,0x7
    80002564:	ac87b783          	ld	a5,-1336(a5) # 80009028 <initproc>
    80002568:	0d050493          	addi	s1,a0,208
    8000256c:	15050913          	addi	s2,a0,336
    80002570:	02a79363          	bne	a5,a0,80002596 <texit+0x4e>
		panic("init exiting");
    80002574:	00006517          	auipc	a0,0x6
    80002578:	d0450513          	addi	a0,a0,-764 # 80008278 <digits+0x238>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
			fileclose(f);
    80002584:	00002097          	auipc	ra,0x2
    80002588:	1e8080e7          	jalr	488(ra) # 8000476c <fileclose>
			p->ofile[fd]=0;
    8000258c:	0004b023          	sd	zero,0(s1)
	for(fd=0;fd<NOFILE;fd++)
    80002590:	04a1                	addi	s1,s1,8
    80002592:	01248563          	beq	s1,s2,8000259c <texit+0x54>
		if(p->ofile[fd])
    80002596:	6088                	ld	a0,0(s1)
    80002598:	f575                	bnez	a0,80002584 <texit+0x3c>
    8000259a:	bfdd                	j	80002590 <texit+0x48>
	begin_op();
    8000259c:	00002097          	auipc	ra,0x2
    800025a0:	d04080e7          	jalr	-764(ra) # 800042a0 <begin_op>
	iput(p->cwd);
    800025a4:	1509b503          	ld	a0,336(s3)
    800025a8:	00001097          	auipc	ra,0x1
    800025ac:	4e0080e7          	jalr	1248(ra) # 80003a88 <iput>
	end_op();
    800025b0:	00002097          	auipc	ra,0x2
    800025b4:	d70080e7          	jalr	-656(ra) # 80004320 <end_op>
	p->cwd = 0;
    800025b8:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800025bc:	0000f497          	auipc	s1,0xf
    800025c0:	cfc48493          	addi	s1,s1,-772 # 800112b8 <wait_lock>
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
	wakeup(p->parent);
    800025ce:	0389b503          	ld	a0,56(s3)
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	dd0080e7          	jalr	-560(ra) # 800023a2 <wakeup>
	p->state = ZOMBIE;
    800025da:	4795                	li	a5,5
    800025dc:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
	sched();
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	b10080e7          	jalr	-1264(ra) # 800020fa <sched>
	panic("zombie exit");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	c9650513          	addi	a0,a0,-874 # 80008288 <digits+0x248>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>

0000000080002602 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002602:	7179                	addi	sp,sp,-48
    80002604:	f406                	sd	ra,40(sp)
    80002606:	f022                	sd	s0,32(sp)
    80002608:	ec26                	sd	s1,24(sp)
    8000260a:	e84a                	sd	s2,16(sp)
    8000260c:	e44e                	sd	s3,8(sp)
    8000260e:	1800                	addi	s0,sp,48
    80002610:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	0000f497          	auipc	s1,0xf
    80002616:	0be48493          	addi	s1,s1,190 # 800116d0 <proc>
    8000261a:	00015997          	auipc	s3,0x15
    8000261e:	ab698993          	addi	s3,s3,-1354 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	5c0080e7          	jalr	1472(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000262c:	589c                	lw	a5,48(s1)
    8000262e:	01278d63          	beq	a5,s2,80002648 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	664080e7          	jalr	1636(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263c:	16848493          	addi	s1,s1,360
    80002640:	ff3491e3          	bne	s1,s3,80002622 <kill+0x20>
  }
  return -1;
    80002644:	557d                	li	a0,-1
    80002646:	a829                	j	80002660 <kill+0x5e>
      p->killed = 1;
    80002648:	4785                	li	a5,1
    8000264a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000264c:	4c98                	lw	a4,24(s1)
    8000264e:	4789                	li	a5,2
    80002650:	00f70f63          	beq	a4,a5,8000266e <kill+0x6c>
      release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
      return 0;
    8000265e:	4501                	li	a0,0
}
    80002660:	70a2                	ld	ra,40(sp)
    80002662:	7402                	ld	s0,32(sp)
    80002664:	64e2                	ld	s1,24(sp)
    80002666:	6942                	ld	s2,16(sp)
    80002668:	69a2                	ld	s3,8(sp)
    8000266a:	6145                	addi	sp,sp,48
    8000266c:	8082                	ret
        p->state = RUNNABLE;
    8000266e:	478d                	li	a5,3
    80002670:	cc9c                	sw	a5,24(s1)
    80002672:	b7cd                	j	80002654 <kill+0x52>

0000000080002674 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002674:	7179                	addi	sp,sp,-48
    80002676:	f406                	sd	ra,40(sp)
    80002678:	f022                	sd	s0,32(sp)
    8000267a:	ec26                	sd	s1,24(sp)
    8000267c:	e84a                	sd	s2,16(sp)
    8000267e:	e44e                	sd	s3,8(sp)
    80002680:	e052                	sd	s4,0(sp)
    80002682:	1800                	addi	s0,sp,48
    80002684:	84aa                	mv	s1,a0
    80002686:	892e                	mv	s2,a1
    80002688:	89b2                	mv	s3,a2
    8000268a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	324080e7          	jalr	804(ra) # 800019b0 <myproc>
  if(user_dst){
    80002694:	c08d                	beqz	s1,800026b6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002696:	86d2                	mv	a3,s4
    80002698:	864e                	mv	a2,s3
    8000269a:	85ca                	mv	a1,s2
    8000269c:	6928                	ld	a0,80(a0)
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	fd4080e7          	jalr	-44(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026a6:	70a2                	ld	ra,40(sp)
    800026a8:	7402                	ld	s0,32(sp)
    800026aa:	64e2                	ld	s1,24(sp)
    800026ac:	6942                	ld	s2,16(sp)
    800026ae:	69a2                	ld	s3,8(sp)
    800026b0:	6a02                	ld	s4,0(sp)
    800026b2:	6145                	addi	sp,sp,48
    800026b4:	8082                	ret
    memmove((char *)dst, src, len);
    800026b6:	000a061b          	sext.w	a2,s4
    800026ba:	85ce                	mv	a1,s3
    800026bc:	854a                	mv	a0,s2
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	682080e7          	jalr	1666(ra) # 80000d40 <memmove>
    return 0;
    800026c6:	8526                	mv	a0,s1
    800026c8:	bff9                	j	800026a6 <either_copyout+0x32>

00000000800026ca <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ca:	7179                	addi	sp,sp,-48
    800026cc:	f406                	sd	ra,40(sp)
    800026ce:	f022                	sd	s0,32(sp)
    800026d0:	ec26                	sd	s1,24(sp)
    800026d2:	e84a                	sd	s2,16(sp)
    800026d4:	e44e                	sd	s3,8(sp)
    800026d6:	e052                	sd	s4,0(sp)
    800026d8:	1800                	addi	s0,sp,48
    800026da:	892a                	mv	s2,a0
    800026dc:	84ae                	mv	s1,a1
    800026de:	89b2                	mv	s3,a2
    800026e0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026e2:	fffff097          	auipc	ra,0xfffff
    800026e6:	2ce080e7          	jalr	718(ra) # 800019b0 <myproc>
  if(user_src){
    800026ea:	c08d                	beqz	s1,8000270c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026ec:	86d2                	mv	a3,s4
    800026ee:	864e                	mv	a2,s3
    800026f0:	85ca                	mv	a1,s2
    800026f2:	6928                	ld	a0,80(a0)
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	00a080e7          	jalr	10(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026fc:	70a2                	ld	ra,40(sp)
    800026fe:	7402                	ld	s0,32(sp)
    80002700:	64e2                	ld	s1,24(sp)
    80002702:	6942                	ld	s2,16(sp)
    80002704:	69a2                	ld	s3,8(sp)
    80002706:	6a02                	ld	s4,0(sp)
    80002708:	6145                	addi	sp,sp,48
    8000270a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000270c:	000a061b          	sext.w	a2,s4
    80002710:	85ce                	mv	a1,s3
    80002712:	854a                	mv	a0,s2
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	62c080e7          	jalr	1580(ra) # 80000d40 <memmove>
    return 0;
    8000271c:	8526                	mv	a0,s1
    8000271e:	bff9                	j	800026fc <either_copyin+0x32>

0000000080002720 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002720:	715d                	addi	sp,sp,-80
    80002722:	e486                	sd	ra,72(sp)
    80002724:	e0a2                	sd	s0,64(sp)
    80002726:	fc26                	sd	s1,56(sp)
    80002728:	f84a                	sd	s2,48(sp)
    8000272a:	f44e                	sd	s3,40(sp)
    8000272c:	f052                	sd	s4,32(sp)
    8000272e:	ec56                	sd	s5,24(sp)
    80002730:	e85a                	sd	s6,16(sp)
    80002732:	e45e                	sd	s7,8(sp)
    80002734:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	99250513          	addi	a0,a0,-1646 # 800080c8 <digits+0x88>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	e4a080e7          	jalr	-438(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002746:	0000f497          	auipc	s1,0xf
    8000274a:	0e248493          	addi	s1,s1,226 # 80011828 <proc+0x158>
    8000274e:	00015917          	auipc	s2,0x15
    80002752:	ada90913          	addi	s2,s2,-1318 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002756:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002758:	00006997          	auipc	s3,0x6
    8000275c:	b4098993          	addi	s3,s3,-1216 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002760:	00006a97          	auipc	s5,0x6
    80002764:	b40a8a93          	addi	s5,s5,-1216 # 800082a0 <digits+0x260>
    printf("\n");
    80002768:	00006a17          	auipc	s4,0x6
    8000276c:	960a0a13          	addi	s4,s4,-1696 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002770:	00006b97          	auipc	s7,0x6
    80002774:	b68b8b93          	addi	s7,s7,-1176 # 800082d8 <states.1741>
    80002778:	a00d                	j	8000279a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000277a:	ed86a583          	lw	a1,-296(a3)
    8000277e:	8556                	mv	a0,s5
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	e08080e7          	jalr	-504(ra) # 80000588 <printf>
    printf("\n");
    80002788:	8552                	mv	a0,s4
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	dfe080e7          	jalr	-514(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002792:	16848493          	addi	s1,s1,360
    80002796:	03248163          	beq	s1,s2,800027b8 <procdump+0x98>
    if(p->state == UNUSED)
    8000279a:	86a6                	mv	a3,s1
    8000279c:	ec04a783          	lw	a5,-320(s1)
    800027a0:	dbed                	beqz	a5,80002792 <procdump+0x72>
      state = "???";
    800027a2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a4:	fcfb6be3          	bltu	s6,a5,8000277a <procdump+0x5a>
    800027a8:	1782                	slli	a5,a5,0x20
    800027aa:	9381                	srli	a5,a5,0x20
    800027ac:	078e                	slli	a5,a5,0x3
    800027ae:	97de                	add	a5,a5,s7
    800027b0:	6390                	ld	a2,0(a5)
    800027b2:	f661                	bnez	a2,8000277a <procdump+0x5a>
      state = "???";
    800027b4:	864e                	mv	a2,s3
    800027b6:	b7d1                	j	8000277a <procdump+0x5a>
  }
}
    800027b8:	60a6                	ld	ra,72(sp)
    800027ba:	6406                	ld	s0,64(sp)
    800027bc:	74e2                	ld	s1,56(sp)
    800027be:	7942                	ld	s2,48(sp)
    800027c0:	79a2                	ld	s3,40(sp)
    800027c2:	7a02                	ld	s4,32(sp)
    800027c4:	6ae2                	ld	s5,24(sp)
    800027c6:	6b42                	ld	s6,16(sp)
    800027c8:	6ba2                	ld	s7,8(sp)
    800027ca:	6161                	addi	sp,sp,80
    800027cc:	8082                	ret

00000000800027ce <swtch>:
    800027ce:	00153023          	sd	ra,0(a0)
    800027d2:	00253423          	sd	sp,8(a0)
    800027d6:	e900                	sd	s0,16(a0)
    800027d8:	ed04                	sd	s1,24(a0)
    800027da:	03253023          	sd	s2,32(a0)
    800027de:	03353423          	sd	s3,40(a0)
    800027e2:	03453823          	sd	s4,48(a0)
    800027e6:	03553c23          	sd	s5,56(a0)
    800027ea:	05653023          	sd	s6,64(a0)
    800027ee:	05753423          	sd	s7,72(a0)
    800027f2:	05853823          	sd	s8,80(a0)
    800027f6:	05953c23          	sd	s9,88(a0)
    800027fa:	07a53023          	sd	s10,96(a0)
    800027fe:	07b53423          	sd	s11,104(a0)
    80002802:	0005b083          	ld	ra,0(a1)
    80002806:	0085b103          	ld	sp,8(a1)
    8000280a:	6980                	ld	s0,16(a1)
    8000280c:	6d84                	ld	s1,24(a1)
    8000280e:	0205b903          	ld	s2,32(a1)
    80002812:	0285b983          	ld	s3,40(a1)
    80002816:	0305ba03          	ld	s4,48(a1)
    8000281a:	0385ba83          	ld	s5,56(a1)
    8000281e:	0405bb03          	ld	s6,64(a1)
    80002822:	0485bb83          	ld	s7,72(a1)
    80002826:	0505bc03          	ld	s8,80(a1)
    8000282a:	0585bc83          	ld	s9,88(a1)
    8000282e:	0605bd03          	ld	s10,96(a1)
    80002832:	0685bd83          	ld	s11,104(a1)
    80002836:	8082                	ret

0000000080002838 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002838:	1141                	addi	sp,sp,-16
    8000283a:	e406                	sd	ra,8(sp)
    8000283c:	e022                	sd	s0,0(sp)
    8000283e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002840:	00006597          	auipc	a1,0x6
    80002844:	ac858593          	addi	a1,a1,-1336 # 80008308 <states.1741+0x30>
    80002848:	00015517          	auipc	a0,0x15
    8000284c:	88850513          	addi	a0,a0,-1912 # 800170d0 <tickslock>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	304080e7          	jalr	772(ra) # 80000b54 <initlock>
}
    80002858:	60a2                	ld	ra,8(sp)
    8000285a:	6402                	ld	s0,0(sp)
    8000285c:	0141                	addi	sp,sp,16
    8000285e:	8082                	ret

0000000080002860 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002860:	1141                	addi	sp,sp,-16
    80002862:	e422                	sd	s0,8(sp)
    80002864:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002866:	00003797          	auipc	a5,0x3
    8000286a:	51a78793          	addi	a5,a5,1306 # 80005d80 <kernelvec>
    8000286e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002872:	6422                	ld	s0,8(sp)
    80002874:	0141                	addi	sp,sp,16
    80002876:	8082                	ret

0000000080002878 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002878:	1141                	addi	sp,sp,-16
    8000287a:	e406                	sd	ra,8(sp)
    8000287c:	e022                	sd	s0,0(sp)
    8000287e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	130080e7          	jalr	304(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000288c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002892:	00004617          	auipc	a2,0x4
    80002896:	76e60613          	addi	a2,a2,1902 # 80007000 <_trampoline>
    8000289a:	00004697          	auipc	a3,0x4
    8000289e:	76668693          	addi	a3,a3,1894 # 80007000 <_trampoline>
    800028a2:	8e91                	sub	a3,a3,a2
    800028a4:	040007b7          	lui	a5,0x4000
    800028a8:	17fd                	addi	a5,a5,-1
    800028aa:	07b2                	slli	a5,a5,0xc
    800028ac:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ae:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028b2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028b4:	180026f3          	csrr	a3,satp
    800028b8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028ba:	6d38                	ld	a4,88(a0)
    800028bc:	6134                	ld	a3,64(a0)
    800028be:	6585                	lui	a1,0x1
    800028c0:	96ae                	add	a3,a3,a1
    800028c2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028c4:	6d38                	ld	a4,88(a0)
    800028c6:	00000697          	auipc	a3,0x0
    800028ca:	13868693          	addi	a3,a3,312 # 800029fe <usertrap>
    800028ce:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028d0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028d2:	8692                	mv	a3,tp
    800028d4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028da:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028de:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028e6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e8:	6f18                	ld	a4,24(a4)
    800028ea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ee:	692c                	ld	a1,80(a0)
    800028f0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028f2:	00004717          	auipc	a4,0x4
    800028f6:	79e70713          	addi	a4,a4,1950 # 80007090 <userret>
    800028fa:	8f11                	sub	a4,a4,a2
    800028fc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028fe:	577d                	li	a4,-1
    80002900:	177e                	slli	a4,a4,0x3f
    80002902:	8dd9                	or	a1,a1,a4
    80002904:	02000537          	lui	a0,0x2000
    80002908:	157d                	addi	a0,a0,-1
    8000290a:	0536                	slli	a0,a0,0xd
    8000290c:	9782                	jalr	a5
}
    8000290e:	60a2                	ld	ra,8(sp)
    80002910:	6402                	ld	s0,0(sp)
    80002912:	0141                	addi	sp,sp,16
    80002914:	8082                	ret

0000000080002916 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002916:	1101                	addi	sp,sp,-32
    80002918:	ec06                	sd	ra,24(sp)
    8000291a:	e822                	sd	s0,16(sp)
    8000291c:	e426                	sd	s1,8(sp)
    8000291e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002920:	00014497          	auipc	s1,0x14
    80002924:	7b048493          	addi	s1,s1,1968 # 800170d0 <tickslock>
    80002928:	8526                	mv	a0,s1
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  ticks++;
    80002932:	00006517          	auipc	a0,0x6
    80002936:	6fe50513          	addi	a0,a0,1790 # 80009030 <ticks>
    8000293a:	411c                	lw	a5,0(a0)
    8000293c:	2785                	addiw	a5,a5,1
    8000293e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002940:	00000097          	auipc	ra,0x0
    80002944:	a62080e7          	jalr	-1438(ra) # 800023a2 <wakeup>
  release(&tickslock);
    80002948:	8526                	mv	a0,s1
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	34e080e7          	jalr	846(ra) # 80000c98 <release>
}
    80002952:	60e2                	ld	ra,24(sp)
    80002954:	6442                	ld	s0,16(sp)
    80002956:	64a2                	ld	s1,8(sp)
    80002958:	6105                	addi	sp,sp,32
    8000295a:	8082                	ret

000000008000295c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000295c:	1101                	addi	sp,sp,-32
    8000295e:	ec06                	sd	ra,24(sp)
    80002960:	e822                	sd	s0,16(sp)
    80002962:	e426                	sd	s1,8(sp)
    80002964:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002966:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000296a:	00074d63          	bltz	a4,80002984 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000296e:	57fd                	li	a5,-1
    80002970:	17fe                	slli	a5,a5,0x3f
    80002972:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002974:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002976:	06f70363          	beq	a4,a5,800029dc <devintr+0x80>
  }
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret
     (scause & 0xff) == 9){
    80002984:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002988:	46a5                	li	a3,9
    8000298a:	fed792e3          	bne	a5,a3,8000296e <devintr+0x12>
    int irq = plic_claim();
    8000298e:	00003097          	auipc	ra,0x3
    80002992:	4fa080e7          	jalr	1274(ra) # 80005e88 <plic_claim>
    80002996:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002998:	47a9                	li	a5,10
    8000299a:	02f50763          	beq	a0,a5,800029c8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000299e:	4785                	li	a5,1
    800029a0:	02f50963          	beq	a0,a5,800029d2 <devintr+0x76>
    return 1;
    800029a4:	4505                	li	a0,1
    } else if(irq){
    800029a6:	d8f1                	beqz	s1,8000297a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029a8:	85a6                	mv	a1,s1
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	96650513          	addi	a0,a0,-1690 # 80008310 <states.1741+0x38>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd6080e7          	jalr	-1066(ra) # 80000588 <printf>
      plic_complete(irq);
    800029ba:	8526                	mv	a0,s1
    800029bc:	00003097          	auipc	ra,0x3
    800029c0:	4f0080e7          	jalr	1264(ra) # 80005eac <plic_complete>
    return 1;
    800029c4:	4505                	li	a0,1
    800029c6:	bf55                	j	8000297a <devintr+0x1e>
      uartintr();
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	fe0080e7          	jalr	-32(ra) # 800009a8 <uartintr>
    800029d0:	b7ed                	j	800029ba <devintr+0x5e>
      virtio_disk_intr();
    800029d2:	00004097          	auipc	ra,0x4
    800029d6:	9ba080e7          	jalr	-1606(ra) # 8000638c <virtio_disk_intr>
    800029da:	b7c5                	j	800029ba <devintr+0x5e>
    if(cpuid() == 0){
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	fa8080e7          	jalr	-88(ra) # 80001984 <cpuid>
    800029e4:	c901                	beqz	a0,800029f4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029e6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ec:	14479073          	csrw	sip,a5
    return 2;
    800029f0:	4509                	li	a0,2
    800029f2:	b761                	j	8000297a <devintr+0x1e>
      clockintr();
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	f22080e7          	jalr	-222(ra) # 80002916 <clockintr>
    800029fc:	b7ed                	j	800029e6 <devintr+0x8a>

00000000800029fe <usertrap>:
{
    800029fe:	1101                	addi	sp,sp,-32
    80002a00:	ec06                	sd	ra,24(sp)
    80002a02:	e822                	sd	s0,16(sp)
    80002a04:	e426                	sd	s1,8(sp)
    80002a06:	e04a                	sd	s2,0(sp)
    80002a08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a0e:	1007f793          	andi	a5,a5,256
    80002a12:	e3ad                	bnez	a5,80002a74 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a14:	00003797          	auipc	a5,0x3
    80002a18:	36c78793          	addi	a5,a5,876 # 80005d80 <kernelvec>
    80002a1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	f90080e7          	jalr	-112(ra) # 800019b0 <myproc>
    80002a28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a2a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2c:	14102773          	csrr	a4,sepc
    80002a30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a36:	47a1                	li	a5,8
    80002a38:	04f71c63          	bne	a4,a5,80002a90 <usertrap+0x92>
    if(p->killed)
    80002a3c:	551c                	lw	a5,40(a0)
    80002a3e:	e3b9                	bnez	a5,80002a84 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a40:	6cb8                	ld	a4,88(s1)
    80002a42:	6f1c                	ld	a5,24(a4)
    80002a44:	0791                	addi	a5,a5,4
    80002a46:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a50:	10079073          	csrw	sstatus,a5
    syscall();
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	2e0080e7          	jalr	736(ra) # 80002d34 <syscall>
  if(p->killed)
    80002a5c:	549c                	lw	a5,40(s1)
    80002a5e:	ebc1                	bnez	a5,80002aee <usertrap+0xf0>
  usertrapret();
    80002a60:	00000097          	auipc	ra,0x0
    80002a64:	e18080e7          	jalr	-488(ra) # 80002878 <usertrapret>
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6902                	ld	s2,0(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret
    panic("usertrap: not from user mode");
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	8bc50513          	addi	a0,a0,-1860 # 80008330 <states.1741+0x58>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>
      exit(-1);
    80002a84:	557d                	li	a0,-1
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	9ec080e7          	jalr	-1556(ra) # 80002472 <exit>
    80002a8e:	bf4d                	j	80002a40 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	ecc080e7          	jalr	-308(ra) # 8000295c <devintr>
    80002a98:	892a                	mv	s2,a0
    80002a9a:	c501                	beqz	a0,80002aa2 <usertrap+0xa4>
  if(p->killed)
    80002a9c:	549c                	lw	a5,40(s1)
    80002a9e:	c3a1                	beqz	a5,80002ade <usertrap+0xe0>
    80002aa0:	a815                	j	80002ad4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aa6:	5890                	lw	a2,48(s1)
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	8a850513          	addi	a0,a0,-1880 # 80008350 <states.1741+0x78>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	ad8080e7          	jalr	-1320(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002abc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac0:	00006517          	auipc	a0,0x6
    80002ac4:	8c050513          	addi	a0,a0,-1856 # 80008380 <states.1741+0xa8>
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	ac0080e7          	jalr	-1344(ra) # 80000588 <printf>
    p->killed = 1;
    80002ad0:	4785                	li	a5,1
    80002ad2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ad4:	557d                	li	a0,-1
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	99c080e7          	jalr	-1636(ra) # 80002472 <exit>
  if(which_dev == 2)
    80002ade:	4789                	li	a5,2
    80002ae0:	f8f910e3          	bne	s2,a5,80002a60 <usertrap+0x62>
    yield();
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	6ec080e7          	jalr	1772(ra) # 800021d0 <yield>
    80002aec:	bf95                	j	80002a60 <usertrap+0x62>
  int which_dev = 0;
    80002aee:	4901                	li	s2,0
    80002af0:	b7d5                	j	80002ad4 <usertrap+0xd6>

0000000080002af2 <kerneltrap>:
{
    80002af2:	7179                	addi	sp,sp,-48
    80002af4:	f406                	sd	ra,40(sp)
    80002af6:	f022                	sd	s0,32(sp)
    80002af8:	ec26                	sd	s1,24(sp)
    80002afa:	e84a                	sd	s2,16(sp)
    80002afc:	e44e                	sd	s3,8(sp)
    80002afe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b0c:	1004f793          	andi	a5,s1,256
    80002b10:	cb85                	beqz	a5,80002b40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b18:	ef85                	bnez	a5,80002b50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	e42080e7          	jalr	-446(ra) # 8000295c <devintr>
    80002b22:	cd1d                	beqz	a0,80002b60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b24:	4789                	li	a5,2
    80002b26:	06f50a63          	beq	a0,a5,80002b9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2e:	10049073          	csrw	sstatus,s1
}
    80002b32:	70a2                	ld	ra,40(sp)
    80002b34:	7402                	ld	s0,32(sp)
    80002b36:	64e2                	ld	s1,24(sp)
    80002b38:	6942                	ld	s2,16(sp)
    80002b3a:	69a2                	ld	s3,8(sp)
    80002b3c:	6145                	addi	sp,sp,48
    80002b3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	86050513          	addi	a0,a0,-1952 # 800083a0 <states.1741+0xc8>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	87850513          	addi	a0,a0,-1928 # 800083c8 <states.1741+0xf0>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	9e6080e7          	jalr	-1562(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b60:	85ce                	mv	a1,s3
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	88650513          	addi	a0,a0,-1914 # 800083e8 <states.1741+0x110>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a1e080e7          	jalr	-1506(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	87e50513          	addi	a0,a0,-1922 # 800083f8 <states.1741+0x120>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a06080e7          	jalr	-1530(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	88650513          	addi	a0,a0,-1914 # 80008410 <states.1741+0x138>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9ac080e7          	jalr	-1620(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	e16080e7          	jalr	-490(ra) # 800019b0 <myproc>
    80002ba2:	d541                	beqz	a0,80002b2a <kerneltrap+0x38>
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	e0c080e7          	jalr	-500(ra) # 800019b0 <myproc>
    80002bac:	4d18                	lw	a4,24(a0)
    80002bae:	4791                	li	a5,4
    80002bb0:	f6f71de3          	bne	a4,a5,80002b2a <kerneltrap+0x38>
    yield();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	61c080e7          	jalr	1564(ra) # 800021d0 <yield>
    80002bbc:	b7bd                	j	80002b2a <kerneltrap+0x38>

0000000080002bbe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	1000                	addi	s0,sp,32
    80002bc8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	de6080e7          	jalr	-538(ra) # 800019b0 <myproc>
  switch (n) {
    80002bd2:	4795                	li	a5,5
    80002bd4:	0497e163          	bltu	a5,s1,80002c16 <argraw+0x58>
    80002bd8:	048a                	slli	s1,s1,0x2
    80002bda:	00006717          	auipc	a4,0x6
    80002bde:	86e70713          	addi	a4,a4,-1938 # 80008448 <states.1741+0x170>
    80002be2:	94ba                	add	s1,s1,a4
    80002be4:	409c                	lw	a5,0(s1)
    80002be6:	97ba                	add	a5,a5,a4
    80002be8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bea:	6d3c                	ld	a5,88(a0)
    80002bec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret
    return p->trapframe->a1;
    80002bf8:	6d3c                	ld	a5,88(a0)
    80002bfa:	7fa8                	ld	a0,120(a5)
    80002bfc:	bfcd                	j	80002bee <argraw+0x30>
    return p->trapframe->a2;
    80002bfe:	6d3c                	ld	a5,88(a0)
    80002c00:	63c8                	ld	a0,128(a5)
    80002c02:	b7f5                	j	80002bee <argraw+0x30>
    return p->trapframe->a3;
    80002c04:	6d3c                	ld	a5,88(a0)
    80002c06:	67c8                	ld	a0,136(a5)
    80002c08:	b7dd                	j	80002bee <argraw+0x30>
    return p->trapframe->a4;
    80002c0a:	6d3c                	ld	a5,88(a0)
    80002c0c:	6bc8                	ld	a0,144(a5)
    80002c0e:	b7c5                	j	80002bee <argraw+0x30>
    return p->trapframe->a5;
    80002c10:	6d3c                	ld	a5,88(a0)
    80002c12:	6fc8                	ld	a0,152(a5)
    80002c14:	bfe9                	j	80002bee <argraw+0x30>
  panic("argraw");
    80002c16:	00006517          	auipc	a0,0x6
    80002c1a:	80a50513          	addi	a0,a0,-2038 # 80008420 <states.1741+0x148>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>

0000000080002c26 <fetchaddr>:
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	e426                	sd	s1,8(sp)
    80002c2e:	e04a                	sd	s2,0(sp)
    80002c30:	1000                	addi	s0,sp,32
    80002c32:	84aa                	mv	s1,a0
    80002c34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	d7a080e7          	jalr	-646(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c3e:	653c                	ld	a5,72(a0)
    80002c40:	02f4f863          	bgeu	s1,a5,80002c70 <fetchaddr+0x4a>
    80002c44:	00848713          	addi	a4,s1,8
    80002c48:	02e7e663          	bltu	a5,a4,80002c74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c4c:	46a1                	li	a3,8
    80002c4e:	8626                	mv	a2,s1
    80002c50:	85ca                	mv	a1,s2
    80002c52:	6928                	ld	a0,80(a0)
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	aaa080e7          	jalr	-1366(ra) # 800016fe <copyin>
    80002c5c:	00a03533          	snez	a0,a0
    80002c60:	40a00533          	neg	a0,a0
}
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6902                	ld	s2,0(sp)
    80002c6c:	6105                	addi	sp,sp,32
    80002c6e:	8082                	ret
    return -1;
    80002c70:	557d                	li	a0,-1
    80002c72:	bfcd                	j	80002c64 <fetchaddr+0x3e>
    80002c74:	557d                	li	a0,-1
    80002c76:	b7fd                	j	80002c64 <fetchaddr+0x3e>

0000000080002c78 <fetchstr>:
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	1800                	addi	s0,sp,48
    80002c86:	892a                	mv	s2,a0
    80002c88:	84ae                	mv	s1,a1
    80002c8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	d24080e7          	jalr	-732(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c94:	86ce                	mv	a3,s3
    80002c96:	864a                	mv	a2,s2
    80002c98:	85a6                	mv	a1,s1
    80002c9a:	6928                	ld	a0,80(a0)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	aee080e7          	jalr	-1298(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002ca4:	00054763          	bltz	a0,80002cb2 <fetchstr+0x3a>
  return strlen(buf);
    80002ca8:	8526                	mv	a0,s1
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	1ba080e7          	jalr	442(ra) # 80000e64 <strlen>
}
    80002cb2:	70a2                	ld	ra,40(sp)
    80002cb4:	7402                	ld	s0,32(sp)
    80002cb6:	64e2                	ld	s1,24(sp)
    80002cb8:	6942                	ld	s2,16(sp)
    80002cba:	69a2                	ld	s3,8(sp)
    80002cbc:	6145                	addi	sp,sp,48
    80002cbe:	8082                	ret

0000000080002cc0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	ef2080e7          	jalr	-270(ra) # 80002bbe <argraw>
    80002cd4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cd6:	4501                	li	a0,0
    80002cd8:	60e2                	ld	ra,24(sp)
    80002cda:	6442                	ld	s0,16(sp)
    80002cdc:	64a2                	ld	s1,8(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	1000                	addi	s0,sp,32
    80002cec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	ed0080e7          	jalr	-304(ra) # 80002bbe <argraw>
    80002cf6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cf8:	4501                	li	a0,0
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	64a2                	ld	s1,8(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	e426                	sd	s1,8(sp)
    80002d0c:	e04a                	sd	s2,0(sp)
    80002d0e:	1000                	addi	s0,sp,32
    80002d10:	84ae                	mv	s1,a1
    80002d12:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	eaa080e7          	jalr	-342(ra) # 80002bbe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d1c:	864a                	mv	a2,s2
    80002d1e:	85a6                	mv	a1,s1
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	f58080e7          	jalr	-168(ra) # 80002c78 <fetchstr>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6902                	ld	s2,0(sp)
    80002d30:	6105                	addi	sp,sp,32
    80002d32:	8082                	ret

0000000080002d34 <syscall>:
[SYS_texit]	  sys_texit, 	//syscall entry
};

void
syscall(void)
{
    80002d34:	1101                	addi	sp,sp,-32
    80002d36:	ec06                	sd	ra,24(sp)
    80002d38:	e822                	sd	s0,16(sp)
    80002d3a:	e426                	sd	s1,8(sp)
    80002d3c:	e04a                	sd	s2,0(sp)
    80002d3e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	c70080e7          	jalr	-912(ra) # 800019b0 <myproc>
    80002d48:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d4a:	05853903          	ld	s2,88(a0)
    80002d4e:	0a893783          	ld	a5,168(s2)
    80002d52:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d56:	37fd                	addiw	a5,a5,-1
    80002d58:	4759                	li	a4,22
    80002d5a:	00f76f63          	bltu	a4,a5,80002d78 <syscall+0x44>
    80002d5e:	00369713          	slli	a4,a3,0x3
    80002d62:	00005797          	auipc	a5,0x5
    80002d66:	6fe78793          	addi	a5,a5,1790 # 80008460 <syscalls>
    80002d6a:	97ba                	add	a5,a5,a4
    80002d6c:	639c                	ld	a5,0(a5)
    80002d6e:	c789                	beqz	a5,80002d78 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d70:	9782                	jalr	a5
    80002d72:	06a93823          	sd	a0,112(s2)
    80002d76:	a839                	j	80002d94 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d78:	15848613          	addi	a2,s1,344
    80002d7c:	588c                	lw	a1,48(s1)
    80002d7e:	00005517          	auipc	a0,0x5
    80002d82:	6aa50513          	addi	a0,a0,1706 # 80008428 <states.1741+0x150>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	802080e7          	jalr	-2046(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d8e:	6cbc                	ld	a5,88(s1)
    80002d90:	577d                	li	a4,-1
    80002d92:	fbb8                	sd	a4,112(a5)
  }
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6902                	ld	s2,0(sp)
    80002d9c:	6105                	addi	sp,sp,32
    80002d9e:	8082                	ret

0000000080002da0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002da8:	fec40593          	addi	a1,s0,-20
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	f12080e7          	jalr	-238(ra) # 80002cc0 <argint>
    return -1;
    80002db6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db8:	00054963          	bltz	a0,80002dca <sys_exit+0x2a>
  exit(n);
    80002dbc:	fec42503          	lw	a0,-20(s0)
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	6b2080e7          	jalr	1714(ra) # 80002472 <exit>
  return 0;  // not reached
    80002dc8:	4781                	li	a5,0
}
    80002dca:	853e                	mv	a0,a5
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dd4:	1141                	addi	sp,sp,-16
    80002dd6:	e406                	sd	ra,8(sp)
    80002dd8:	e022                	sd	s0,0(sp)
    80002dda:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	bd4080e7          	jalr	-1068(ra) # 800019b0 <myproc>
}
    80002de4:	5908                	lw	a0,48(a0)
    80002de6:	60a2                	ld	ra,8(sp)
    80002de8:	6402                	ld	s0,0(sp)
    80002dea:	0141                	addi	sp,sp,16
    80002dec:	8082                	ret

0000000080002dee <sys_fork>:

uint64
sys_fork(void)
{
    80002dee:	1141                	addi	sp,sp,-16
    80002df0:	e406                	sd	ra,8(sp)
    80002df2:	e022                	sd	s0,0(sp)
    80002df4:	0800                	addi	s0,sp,16
  return fork();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	f88080e7          	jalr	-120(ra) # 80001d7e <fork>
}
    80002dfe:	60a2                	ld	ra,8(sp)
    80002e00:	6402                	ld	s0,0(sp)
    80002e02:	0141                	addi	sp,sp,16
    80002e04:	8082                	ret

0000000080002e06 <sys_wait>:

uint64
sys_wait(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e0e:	fe840593          	addi	a1,s0,-24
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	ece080e7          	jalr	-306(ra) # 80002ce2 <argaddr>
    80002e1c:	87aa                	mv	a5,a0
    return -1;
    80002e1e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e20:	0007c863          	bltz	a5,80002e30 <sys_wait+0x2a>
  return wait(p);
    80002e24:	fe843503          	ld	a0,-24(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	448080e7          	jalr	1096(ra) # 80002270 <wait>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e38:	7179                	addi	sp,sp,-48
    80002e3a:	f406                	sd	ra,40(sp)
    80002e3c:	f022                	sd	s0,32(sp)
    80002e3e:	ec26                	sd	s1,24(sp)
    80002e40:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e42:	fdc40593          	addi	a1,s0,-36
    80002e46:	4501                	li	a0,0
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	e78080e7          	jalr	-392(ra) # 80002cc0 <argint>
    80002e50:	87aa                	mv	a5,a0
    return -1;
    80002e52:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e54:	0207c063          	bltz	a5,80002e74 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	b58080e7          	jalr	-1192(ra) # 800019b0 <myproc>
    80002e60:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e62:	fdc42503          	lw	a0,-36(s0)
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	ea4080e7          	jalr	-348(ra) # 80001d0a <growproc>
    80002e6e:	00054863          	bltz	a0,80002e7e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e72:	8526                	mv	a0,s1
}
    80002e74:	70a2                	ld	ra,40(sp)
    80002e76:	7402                	ld	s0,32(sp)
    80002e78:	64e2                	ld	s1,24(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    return -1;
    80002e7e:	557d                	li	a0,-1
    80002e80:	bfd5                	j	80002e74 <sys_sbrk+0x3c>

0000000080002e82 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e82:	7139                	addi	sp,sp,-64
    80002e84:	fc06                	sd	ra,56(sp)
    80002e86:	f822                	sd	s0,48(sp)
    80002e88:	f426                	sd	s1,40(sp)
    80002e8a:	f04a                	sd	s2,32(sp)
    80002e8c:	ec4e                	sd	s3,24(sp)
    80002e8e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e90:	fcc40593          	addi	a1,s0,-52
    80002e94:	4501                	li	a0,0
    80002e96:	00000097          	auipc	ra,0x0
    80002e9a:	e2a080e7          	jalr	-470(ra) # 80002cc0 <argint>
    return -1;
    80002e9e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ea0:	06054563          	bltz	a0,80002f0a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ea4:	00014517          	auipc	a0,0x14
    80002ea8:	22c50513          	addi	a0,a0,556 # 800170d0 <tickslock>
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	d38080e7          	jalr	-712(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002eb4:	00006917          	auipc	s2,0x6
    80002eb8:	17c92903          	lw	s2,380(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002ebc:	fcc42783          	lw	a5,-52(s0)
    80002ec0:	cf85                	beqz	a5,80002ef8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ec2:	00014997          	auipc	s3,0x14
    80002ec6:	20e98993          	addi	s3,s3,526 # 800170d0 <tickslock>
    80002eca:	00006497          	auipc	s1,0x6
    80002ece:	16648493          	addi	s1,s1,358 # 80009030 <ticks>
    if(myproc()->killed){
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	ade080e7          	jalr	-1314(ra) # 800019b0 <myproc>
    80002eda:	551c                	lw	a5,40(a0)
    80002edc:	ef9d                	bnez	a5,80002f1a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ede:	85ce                	mv	a1,s3
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	32a080e7          	jalr	810(ra) # 8000220c <sleep>
  while(ticks - ticks0 < n){
    80002eea:	409c                	lw	a5,0(s1)
    80002eec:	412787bb          	subw	a5,a5,s2
    80002ef0:	fcc42703          	lw	a4,-52(s0)
    80002ef4:	fce7efe3          	bltu	a5,a4,80002ed2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	1d850513          	addi	a0,a0,472 # 800170d0 <tickslock>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	d98080e7          	jalr	-616(ra) # 80000c98 <release>
  return 0;
    80002f08:	4781                	li	a5,0
}
    80002f0a:	853e                	mv	a0,a5
    80002f0c:	70e2                	ld	ra,56(sp)
    80002f0e:	7442                	ld	s0,48(sp)
    80002f10:	74a2                	ld	s1,40(sp)
    80002f12:	7902                	ld	s2,32(sp)
    80002f14:	69e2                	ld	s3,24(sp)
    80002f16:	6121                	addi	sp,sp,64
    80002f18:	8082                	ret
      release(&tickslock);
    80002f1a:	00014517          	auipc	a0,0x14
    80002f1e:	1b650513          	addi	a0,a0,438 # 800170d0 <tickslock>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	d76080e7          	jalr	-650(ra) # 80000c98 <release>
      return -1;
    80002f2a:	57fd                	li	a5,-1
    80002f2c:	bff9                	j	80002f0a <sys_sleep+0x88>

0000000080002f2e <sys_kill>:

uint64
sys_kill(void)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f36:	fec40593          	addi	a1,s0,-20
    80002f3a:	4501                	li	a0,0
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	d84080e7          	jalr	-636(ra) # 80002cc0 <argint>
    80002f44:	87aa                	mv	a5,a0
    return -1;
    80002f46:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f48:	0007c863          	bltz	a5,80002f58 <sys_kill+0x2a>
  return kill(pid);
    80002f4c:	fec42503          	lw	a0,-20(s0)
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	6b2080e7          	jalr	1714(ra) # 80002602 <kill>
}
    80002f58:	60e2                	ld	ra,24(sp)
    80002f5a:	6442                	ld	s0,16(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	e426                	sd	s1,8(sp)
    80002f68:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	16650513          	addi	a0,a0,358 # 800170d0 <tickslock>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	c72080e7          	jalr	-910(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f7a:	00006497          	auipc	s1,0x6
    80002f7e:	0b64a483          	lw	s1,182(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	14e50513          	addi	a0,a0,334 # 800170d0 <tickslock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	d0e080e7          	jalr	-754(ra) # 80000c98 <release>
  return xticks;
}
    80002f92:	02049513          	slli	a0,s1,0x20
    80002f96:	9101                	srli	a0,a0,0x20
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret

0000000080002fa2 <sys_clone>:

uint64
sys_clone(void)
{
    80002fa2:	7179                	addi	sp,sp,-48
    80002fa4:	f406                	sd	ra,40(sp)
    80002fa6:	f022                	sd	s0,32(sp)
    80002fa8:	1800                	addi	s0,sp,48
	int size;
	void *func;
	void *arg;
	
	
	if(argstr(0,(char*)(&stack),sizeof(stack))<0)
    80002faa:	4621                	li	a2,8
    80002fac:	fe840593          	addi	a1,s0,-24
    80002fb0:	4501                	li	a0,0
    80002fb2:	00000097          	auipc	ra,0x0
    80002fb6:	d52080e7          	jalr	-686(ra) # 80002d04 <argstr>
	{
		return -1;
    80002fba:	57fd                	li	a5,-1
	if(argstr(0,(char*)(&stack),sizeof(stack))<0)
    80002fbc:	04054f63          	bltz	a0,8000301a <sys_clone+0x78>
	}
	if(argint(1,&size)<0)
    80002fc0:	fe440593          	addi	a1,s0,-28
    80002fc4:	4505                	li	a0,1
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	cfa080e7          	jalr	-774(ra) # 80002cc0 <argint>
	{
		return -1;
    80002fce:	57fd                	li	a5,-1
	if(argint(1,&size)<0)
    80002fd0:	04054563          	bltz	a0,8000301a <sys_clone+0x78>
	}
	if(argstr(2,(char*)(&func),sizeof(func))<0)
    80002fd4:	4621                	li	a2,8
    80002fd6:	fd840593          	addi	a1,s0,-40
    80002fda:	4509                	li	a0,2
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	d28080e7          	jalr	-728(ra) # 80002d04 <argstr>
	{
		return -1;
    80002fe4:	57fd                	li	a5,-1
	if(argstr(2,(char*)(&func),sizeof(func))<0)
    80002fe6:	02054a63          	bltz	a0,8000301a <sys_clone+0x78>
	}
	if(argstr(3,(char*)(&arg),sizeof(arg))<0)
    80002fea:	4621                	li	a2,8
    80002fec:	fd040593          	addi	a1,s0,-48
    80002ff0:	450d                	li	a0,3
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	d12080e7          	jalr	-750(ra) # 80002d04 <argstr>
	{
		return -1;
    80002ffa:	57fd                	li	a5,-1
	if(argstr(3,(char*)(&arg),sizeof(arg))<0)
    80002ffc:	00054f63          	bltz	a0,8000301a <sys_clone+0x78>
	}
	
	
	return clone((void*)stack,size,(void*)func,(void*)arg);
    80003000:	fd043683          	ld	a3,-48(s0)
    80003004:	fd843603          	ld	a2,-40(s0)
    80003008:	fe442583          	lw	a1,-28(s0)
    8000300c:	fe843503          	ld	a0,-24(s0)
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	eaa080e7          	jalr	-342(ra) # 80001eba <clone>
    80003018:	87aa                	mv	a5,a0
		
}
    8000301a:	853e                	mv	a0,a5
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	6145                	addi	sp,sp,48
    80003022:	8082                	ret

0000000080003024 <sys_texit>:

uint64
sys_texit(void)
{
    80003024:	1141                	addi	sp,sp,-16
    80003026:	e406                	sd	ra,8(sp)
    80003028:	e022                	sd	s0,0(sp)
    8000302a:	0800                	addi	s0,sp,16
	texit();
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	51c080e7          	jalr	1308(ra) # 80002548 <texit>
	return 0;
}
    80003034:	4501                	li	a0,0
    80003036:	60a2                	ld	ra,8(sp)
    80003038:	6402                	ld	s0,0(sp)
    8000303a:	0141                	addi	sp,sp,16
    8000303c:	8082                	ret

000000008000303e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	e052                	sd	s4,0(sp)
    8000304c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000304e:	00005597          	auipc	a1,0x5
    80003052:	4d258593          	addi	a1,a1,1234 # 80008520 <syscalls+0xc0>
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	09250513          	addi	a0,a0,146 # 800170e8 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	af6080e7          	jalr	-1290(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003066:	0001c797          	auipc	a5,0x1c
    8000306a:	08278793          	addi	a5,a5,130 # 8001f0e8 <bcache+0x8000>
    8000306e:	0001c717          	auipc	a4,0x1c
    80003072:	2e270713          	addi	a4,a4,738 # 8001f350 <bcache+0x8268>
    80003076:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000307e:	00014497          	auipc	s1,0x14
    80003082:	08248493          	addi	s1,s1,130 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80003086:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003088:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308a:	00005a17          	auipc	s4,0x5
    8000308e:	49ea0a13          	addi	s4,s4,1182 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003092:	2b893783          	ld	a5,696(s2)
    80003096:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003098:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000309c:	85d2                	mv	a1,s4
    8000309e:	01048513          	addi	a0,s1,16
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	4bc080e7          	jalr	1212(ra) # 8000455e <initsleeplock>
    bcache.head.next->prev = b;
    800030aa:	2b893783          	ld	a5,696(s2)
    800030ae:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b4:	45848493          	addi	s1,s1,1112
    800030b8:	fd349de3          	bne	s1,s3,80003092 <binit+0x54>
  }
}
    800030bc:	70a2                	ld	ra,40(sp)
    800030be:	7402                	ld	s0,32(sp)
    800030c0:	64e2                	ld	s1,24(sp)
    800030c2:	6942                	ld	s2,16(sp)
    800030c4:	69a2                	ld	s3,8(sp)
    800030c6:	6a02                	ld	s4,0(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret

00000000800030cc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030cc:	7179                	addi	sp,sp,-48
    800030ce:	f406                	sd	ra,40(sp)
    800030d0:	f022                	sd	s0,32(sp)
    800030d2:	ec26                	sd	s1,24(sp)
    800030d4:	e84a                	sd	s2,16(sp)
    800030d6:	e44e                	sd	s3,8(sp)
    800030d8:	1800                	addi	s0,sp,48
    800030da:	89aa                	mv	s3,a0
    800030dc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030de:	00014517          	auipc	a0,0x14
    800030e2:	00a50513          	addi	a0,a0,10 # 800170e8 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	afe080e7          	jalr	-1282(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030ee:	0001c497          	auipc	s1,0x1c
    800030f2:	2b24b483          	ld	s1,690(s1) # 8001f3a0 <bcache+0x82b8>
    800030f6:	0001c797          	auipc	a5,0x1c
    800030fa:	25a78793          	addi	a5,a5,602 # 8001f350 <bcache+0x8268>
    800030fe:	02f48f63          	beq	s1,a5,8000313c <bread+0x70>
    80003102:	873e                	mv	a4,a5
    80003104:	a021                	j	8000310c <bread+0x40>
    80003106:	68a4                	ld	s1,80(s1)
    80003108:	02e48a63          	beq	s1,a4,8000313c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000310c:	449c                	lw	a5,8(s1)
    8000310e:	ff379ce3          	bne	a5,s3,80003106 <bread+0x3a>
    80003112:	44dc                	lw	a5,12(s1)
    80003114:	ff2799e3          	bne	a5,s2,80003106 <bread+0x3a>
      b->refcnt++;
    80003118:	40bc                	lw	a5,64(s1)
    8000311a:	2785                	addiw	a5,a5,1
    8000311c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000311e:	00014517          	auipc	a0,0x14
    80003122:	fca50513          	addi	a0,a0,-54 # 800170e8 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000312e:	01048513          	addi	a0,s1,16
    80003132:	00001097          	auipc	ra,0x1
    80003136:	466080e7          	jalr	1126(ra) # 80004598 <acquiresleep>
      return b;
    8000313a:	a8b9                	j	80003198 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000313c:	0001c497          	auipc	s1,0x1c
    80003140:	25c4b483          	ld	s1,604(s1) # 8001f398 <bcache+0x82b0>
    80003144:	0001c797          	auipc	a5,0x1c
    80003148:	20c78793          	addi	a5,a5,524 # 8001f350 <bcache+0x8268>
    8000314c:	00f48863          	beq	s1,a5,8000315c <bread+0x90>
    80003150:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003152:	40bc                	lw	a5,64(s1)
    80003154:	cf81                	beqz	a5,8000316c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003156:	64a4                	ld	s1,72(s1)
    80003158:	fee49de3          	bne	s1,a4,80003152 <bread+0x86>
  panic("bget: no buffers");
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	3d450513          	addi	a0,a0,980 # 80008530 <syscalls+0xd0>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
      b->dev = dev;
    8000316c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003170:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003174:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003178:	4785                	li	a5,1
    8000317a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	f6c50513          	addi	a0,a0,-148 # 800170e8 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b14080e7          	jalr	-1260(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000318c:	01048513          	addi	a0,s1,16
    80003190:	00001097          	auipc	ra,0x1
    80003194:	408080e7          	jalr	1032(ra) # 80004598 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003198:	409c                	lw	a5,0(s1)
    8000319a:	cb89                	beqz	a5,800031ac <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000319c:	8526                	mv	a0,s1
    8000319e:	70a2                	ld	ra,40(sp)
    800031a0:	7402                	ld	s0,32(sp)
    800031a2:	64e2                	ld	s1,24(sp)
    800031a4:	6942                	ld	s2,16(sp)
    800031a6:	69a2                	ld	s3,8(sp)
    800031a8:	6145                	addi	sp,sp,48
    800031aa:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ac:	4581                	li	a1,0
    800031ae:	8526                	mv	a0,s1
    800031b0:	00003097          	auipc	ra,0x3
    800031b4:	f06080e7          	jalr	-250(ra) # 800060b6 <virtio_disk_rw>
    b->valid = 1;
    800031b8:	4785                	li	a5,1
    800031ba:	c09c                	sw	a5,0(s1)
  return b;
    800031bc:	b7c5                	j	8000319c <bread+0xd0>

00000000800031be <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ca:	0541                	addi	a0,a0,16
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	466080e7          	jalr	1126(ra) # 80004632 <holdingsleep>
    800031d4:	cd01                	beqz	a0,800031ec <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031d6:	4585                	li	a1,1
    800031d8:	8526                	mv	a0,s1
    800031da:	00003097          	auipc	ra,0x3
    800031de:	edc080e7          	jalr	-292(ra) # 800060b6 <virtio_disk_rw>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	64a2                	ld	s1,8(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret
    panic("bwrite");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	35c50513          	addi	a0,a0,860 # 80008548 <syscalls+0xe8>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	34a080e7          	jalr	842(ra) # 8000053e <panic>

00000000800031fc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031fc:	1101                	addi	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	e04a                	sd	s2,0(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320a:	01050913          	addi	s2,a0,16
    8000320e:	854a                	mv	a0,s2
    80003210:	00001097          	auipc	ra,0x1
    80003214:	422080e7          	jalr	1058(ra) # 80004632 <holdingsleep>
    80003218:	c92d                	beqz	a0,8000328a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	3d2080e7          	jalr	978(ra) # 800045ee <releasesleep>

  acquire(&bcache.lock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	ec450513          	addi	a0,a0,-316 # 800170e8 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	9b8080e7          	jalr	-1608(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003234:	40bc                	lw	a5,64(s1)
    80003236:	37fd                	addiw	a5,a5,-1
    80003238:	0007871b          	sext.w	a4,a5
    8000323c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000323e:	eb05                	bnez	a4,8000326e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003240:	68bc                	ld	a5,80(s1)
    80003242:	64b8                	ld	a4,72(s1)
    80003244:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003246:	64bc                	ld	a5,72(s1)
    80003248:	68b8                	ld	a4,80(s1)
    8000324a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000324c:	0001c797          	auipc	a5,0x1c
    80003250:	e9c78793          	addi	a5,a5,-356 # 8001f0e8 <bcache+0x8000>
    80003254:	2b87b703          	ld	a4,696(a5)
    80003258:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325a:	0001c717          	auipc	a4,0x1c
    8000325e:	0f670713          	addi	a4,a4,246 # 8001f350 <bcache+0x8268>
    80003262:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003264:	2b87b703          	ld	a4,696(a5)
    80003268:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000326e:	00014517          	auipc	a0,0x14
    80003272:	e7a50513          	addi	a0,a0,-390 # 800170e8 <bcache>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6902                	ld	s2,0(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret
    panic("brelse");
    8000328a:	00005517          	auipc	a0,0x5
    8000328e:	2c650513          	addi	a0,a0,710 # 80008550 <syscalls+0xf0>
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2ac080e7          	jalr	684(ra) # 8000053e <panic>

000000008000329a <bpin>:

void
bpin(struct buf *b) {
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a6:	00014517          	auipc	a0,0x14
    800032aa:	e4250513          	addi	a0,a0,-446 # 800170e8 <bcache>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032b6:	40bc                	lw	a5,64(s1)
    800032b8:	2785                	addiw	a5,a5,1
    800032ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032bc:	00014517          	auipc	a0,0x14
    800032c0:	e2c50513          	addi	a0,a0,-468 # 800170e8 <bcache>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	9d4080e7          	jalr	-1580(ra) # 80000c98 <release>
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret

00000000800032d6 <bunpin>:

void
bunpin(struct buf *b) {
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	1000                	addi	s0,sp,32
    800032e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e2:	00014517          	auipc	a0,0x14
    800032e6:	e0650513          	addi	a0,a0,-506 # 800170e8 <bcache>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032f2:	40bc                	lw	a5,64(s1)
    800032f4:	37fd                	addiw	a5,a5,-1
    800032f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	df050513          	addi	a0,a0,-528 # 800170e8 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	998080e7          	jalr	-1640(ra) # 80000c98 <release>
}
    80003308:	60e2                	ld	ra,24(sp)
    8000330a:	6442                	ld	s0,16(sp)
    8000330c:	64a2                	ld	s1,8(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	e426                	sd	s1,8(sp)
    8000331a:	e04a                	sd	s2,0(sp)
    8000331c:	1000                	addi	s0,sp,32
    8000331e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003320:	00d5d59b          	srliw	a1,a1,0xd
    80003324:	0001c797          	auipc	a5,0x1c
    80003328:	4a07a783          	lw	a5,1184(a5) # 8001f7c4 <sb+0x1c>
    8000332c:	9dbd                	addw	a1,a1,a5
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	d9e080e7          	jalr	-610(ra) # 800030cc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003336:	0074f713          	andi	a4,s1,7
    8000333a:	4785                	li	a5,1
    8000333c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003340:	14ce                	slli	s1,s1,0x33
    80003342:	90d9                	srli	s1,s1,0x36
    80003344:	00950733          	add	a4,a0,s1
    80003348:	05874703          	lbu	a4,88(a4)
    8000334c:	00e7f6b3          	and	a3,a5,a4
    80003350:	c69d                	beqz	a3,8000337e <bfree+0x6c>
    80003352:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003354:	94aa                	add	s1,s1,a0
    80003356:	fff7c793          	not	a5,a5
    8000335a:	8ff9                	and	a5,a5,a4
    8000335c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003360:	00001097          	auipc	ra,0x1
    80003364:	118080e7          	jalr	280(ra) # 80004478 <log_write>
  brelse(bp);
    80003368:	854a                	mv	a0,s2
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	e92080e7          	jalr	-366(ra) # 800031fc <brelse>
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	64a2                	ld	s1,8(sp)
    80003378:	6902                	ld	s2,0(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret
    panic("freeing free block");
    8000337e:	00005517          	auipc	a0,0x5
    80003382:	1da50513          	addi	a0,a0,474 # 80008558 <syscalls+0xf8>
    80003386:	ffffd097          	auipc	ra,0xffffd
    8000338a:	1b8080e7          	jalr	440(ra) # 8000053e <panic>

000000008000338e <balloc>:
{
    8000338e:	711d                	addi	sp,sp,-96
    80003390:	ec86                	sd	ra,88(sp)
    80003392:	e8a2                	sd	s0,80(sp)
    80003394:	e4a6                	sd	s1,72(sp)
    80003396:	e0ca                	sd	s2,64(sp)
    80003398:	fc4e                	sd	s3,56(sp)
    8000339a:	f852                	sd	s4,48(sp)
    8000339c:	f456                	sd	s5,40(sp)
    8000339e:	f05a                	sd	s6,32(sp)
    800033a0:	ec5e                	sd	s7,24(sp)
    800033a2:	e862                	sd	s8,16(sp)
    800033a4:	e466                	sd	s9,8(sp)
    800033a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033a8:	0001c797          	auipc	a5,0x1c
    800033ac:	4047a783          	lw	a5,1028(a5) # 8001f7ac <sb+0x4>
    800033b0:	cbd1                	beqz	a5,80003444 <balloc+0xb6>
    800033b2:	8baa                	mv	s7,a0
    800033b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033b6:	0001cb17          	auipc	s6,0x1c
    800033ba:	3f2b0b13          	addi	s6,s6,1010 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033c4:	6c89                	lui	s9,0x2
    800033c6:	a831                	j	800033e2 <balloc+0x54>
    brelse(bp);
    800033c8:	854a                	mv	a0,s2
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	e32080e7          	jalr	-462(ra) # 800031fc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d2:	015c87bb          	addw	a5,s9,s5
    800033d6:	00078a9b          	sext.w	s5,a5
    800033da:	004b2703          	lw	a4,4(s6)
    800033de:	06eaf363          	bgeu	s5,a4,80003444 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033e2:	41fad79b          	sraiw	a5,s5,0x1f
    800033e6:	0137d79b          	srliw	a5,a5,0x13
    800033ea:	015787bb          	addw	a5,a5,s5
    800033ee:	40d7d79b          	sraiw	a5,a5,0xd
    800033f2:	01cb2583          	lw	a1,28(s6)
    800033f6:	9dbd                	addw	a1,a1,a5
    800033f8:	855e                	mv	a0,s7
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	cd2080e7          	jalr	-814(ra) # 800030cc <bread>
    80003402:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003404:	004b2503          	lw	a0,4(s6)
    80003408:	000a849b          	sext.w	s1,s5
    8000340c:	8662                	mv	a2,s8
    8000340e:	faa4fde3          	bgeu	s1,a0,800033c8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003412:	41f6579b          	sraiw	a5,a2,0x1f
    80003416:	01d7d69b          	srliw	a3,a5,0x1d
    8000341a:	00c6873b          	addw	a4,a3,a2
    8000341e:	00777793          	andi	a5,a4,7
    80003422:	9f95                	subw	a5,a5,a3
    80003424:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003428:	4037571b          	sraiw	a4,a4,0x3
    8000342c:	00e906b3          	add	a3,s2,a4
    80003430:	0586c683          	lbu	a3,88(a3)
    80003434:	00d7f5b3          	and	a1,a5,a3
    80003438:	cd91                	beqz	a1,80003454 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343a:	2605                	addiw	a2,a2,1
    8000343c:	2485                	addiw	s1,s1,1
    8000343e:	fd4618e3          	bne	a2,s4,8000340e <balloc+0x80>
    80003442:	b759                	j	800033c8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003444:	00005517          	auipc	a0,0x5
    80003448:	12c50513          	addi	a0,a0,300 # 80008570 <syscalls+0x110>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	0f2080e7          	jalr	242(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003454:	974a                	add	a4,a4,s2
    80003456:	8fd5                	or	a5,a5,a3
    80003458:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000345c:	854a                	mv	a0,s2
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	01a080e7          	jalr	26(ra) # 80004478 <log_write>
        brelse(bp);
    80003466:	854a                	mv	a0,s2
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	d94080e7          	jalr	-620(ra) # 800031fc <brelse>
  bp = bread(dev, bno);
    80003470:	85a6                	mv	a1,s1
    80003472:	855e                	mv	a0,s7
    80003474:	00000097          	auipc	ra,0x0
    80003478:	c58080e7          	jalr	-936(ra) # 800030cc <bread>
    8000347c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000347e:	40000613          	li	a2,1024
    80003482:	4581                	li	a1,0
    80003484:	05850513          	addi	a0,a0,88
    80003488:	ffffe097          	auipc	ra,0xffffe
    8000348c:	858080e7          	jalr	-1960(ra) # 80000ce0 <memset>
  log_write(bp);
    80003490:	854a                	mv	a0,s2
    80003492:	00001097          	auipc	ra,0x1
    80003496:	fe6080e7          	jalr	-26(ra) # 80004478 <log_write>
  brelse(bp);
    8000349a:	854a                	mv	a0,s2
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	d60080e7          	jalr	-672(ra) # 800031fc <brelse>
}
    800034a4:	8526                	mv	a0,s1
    800034a6:	60e6                	ld	ra,88(sp)
    800034a8:	6446                	ld	s0,80(sp)
    800034aa:	64a6                	ld	s1,72(sp)
    800034ac:	6906                	ld	s2,64(sp)
    800034ae:	79e2                	ld	s3,56(sp)
    800034b0:	7a42                	ld	s4,48(sp)
    800034b2:	7aa2                	ld	s5,40(sp)
    800034b4:	7b02                	ld	s6,32(sp)
    800034b6:	6be2                	ld	s7,24(sp)
    800034b8:	6c42                	ld	s8,16(sp)
    800034ba:	6ca2                	ld	s9,8(sp)
    800034bc:	6125                	addi	sp,sp,96
    800034be:	8082                	ret

00000000800034c0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034c0:	7179                	addi	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	e052                	sd	s4,0(sp)
    800034ce:	1800                	addi	s0,sp,48
    800034d0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d2:	47ad                	li	a5,11
    800034d4:	04b7fe63          	bgeu	a5,a1,80003530 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034d8:	ff45849b          	addiw	s1,a1,-12
    800034dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e0:	0ff00793          	li	a5,255
    800034e4:	0ae7e363          	bltu	a5,a4,8000358a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034e8:	08052583          	lw	a1,128(a0)
    800034ec:	c5ad                	beqz	a1,80003556 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034ee:	00092503          	lw	a0,0(s2)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	bda080e7          	jalr	-1062(ra) # 800030cc <bread>
    800034fa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034fc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003500:	02049593          	slli	a1,s1,0x20
    80003504:	9181                	srli	a1,a1,0x20
    80003506:	058a                	slli	a1,a1,0x2
    80003508:	00b784b3          	add	s1,a5,a1
    8000350c:	0004a983          	lw	s3,0(s1)
    80003510:	04098d63          	beqz	s3,8000356a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003514:	8552                	mv	a0,s4
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	ce6080e7          	jalr	-794(ra) # 800031fc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000351e:	854e                	mv	a0,s3
    80003520:	70a2                	ld	ra,40(sp)
    80003522:	7402                	ld	s0,32(sp)
    80003524:	64e2                	ld	s1,24(sp)
    80003526:	6942                	ld	s2,16(sp)
    80003528:	69a2                	ld	s3,8(sp)
    8000352a:	6a02                	ld	s4,0(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003530:	02059493          	slli	s1,a1,0x20
    80003534:	9081                	srli	s1,s1,0x20
    80003536:	048a                	slli	s1,s1,0x2
    80003538:	94aa                	add	s1,s1,a0
    8000353a:	0504a983          	lw	s3,80(s1)
    8000353e:	fe0990e3          	bnez	s3,8000351e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003542:	4108                	lw	a0,0(a0)
    80003544:	00000097          	auipc	ra,0x0
    80003548:	e4a080e7          	jalr	-438(ra) # 8000338e <balloc>
    8000354c:	0005099b          	sext.w	s3,a0
    80003550:	0534a823          	sw	s3,80(s1)
    80003554:	b7e9                	j	8000351e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003556:	4108                	lw	a0,0(a0)
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	e36080e7          	jalr	-458(ra) # 8000338e <balloc>
    80003560:	0005059b          	sext.w	a1,a0
    80003564:	08b92023          	sw	a1,128(s2)
    80003568:	b759                	j	800034ee <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000356a:	00092503          	lw	a0,0(s2)
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	e20080e7          	jalr	-480(ra) # 8000338e <balloc>
    80003576:	0005099b          	sext.w	s3,a0
    8000357a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000357e:	8552                	mv	a0,s4
    80003580:	00001097          	auipc	ra,0x1
    80003584:	ef8080e7          	jalr	-264(ra) # 80004478 <log_write>
    80003588:	b771                	j	80003514 <bmap+0x54>
  panic("bmap: out of range");
    8000358a:	00005517          	auipc	a0,0x5
    8000358e:	ffe50513          	addi	a0,a0,-2 # 80008588 <syscalls+0x128>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>

000000008000359a <iget>:
{
    8000359a:	7179                	addi	sp,sp,-48
    8000359c:	f406                	sd	ra,40(sp)
    8000359e:	f022                	sd	s0,32(sp)
    800035a0:	ec26                	sd	s1,24(sp)
    800035a2:	e84a                	sd	s2,16(sp)
    800035a4:	e44e                	sd	s3,8(sp)
    800035a6:	e052                	sd	s4,0(sp)
    800035a8:	1800                	addi	s0,sp,48
    800035aa:	89aa                	mv	s3,a0
    800035ac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035ae:	0001c517          	auipc	a0,0x1c
    800035b2:	21a50513          	addi	a0,a0,538 # 8001f7c8 <itable>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  empty = 0;
    800035be:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c0:	0001c497          	auipc	s1,0x1c
    800035c4:	22048493          	addi	s1,s1,544 # 8001f7e0 <itable+0x18>
    800035c8:	0001e697          	auipc	a3,0x1e
    800035cc:	ca868693          	addi	a3,a3,-856 # 80021270 <log>
    800035d0:	a039                	j	800035de <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d2:	02090b63          	beqz	s2,80003608 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d6:	08848493          	addi	s1,s1,136
    800035da:	02d48a63          	beq	s1,a3,8000360e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035de:	449c                	lw	a5,8(s1)
    800035e0:	fef059e3          	blez	a5,800035d2 <iget+0x38>
    800035e4:	4098                	lw	a4,0(s1)
    800035e6:	ff3716e3          	bne	a4,s3,800035d2 <iget+0x38>
    800035ea:	40d8                	lw	a4,4(s1)
    800035ec:	ff4713e3          	bne	a4,s4,800035d2 <iget+0x38>
      ip->ref++;
    800035f0:	2785                	addiw	a5,a5,1
    800035f2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035f4:	0001c517          	auipc	a0,0x1c
    800035f8:	1d450513          	addi	a0,a0,468 # 8001f7c8 <itable>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	69c080e7          	jalr	1692(ra) # 80000c98 <release>
      return ip;
    80003604:	8926                	mv	s2,s1
    80003606:	a03d                	j	80003634 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003608:	f7f9                	bnez	a5,800035d6 <iget+0x3c>
    8000360a:	8926                	mv	s2,s1
    8000360c:	b7e9                	j	800035d6 <iget+0x3c>
  if(empty == 0)
    8000360e:	02090c63          	beqz	s2,80003646 <iget+0xac>
  ip->dev = dev;
    80003612:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003616:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000361a:	4785                	li	a5,1
    8000361c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003620:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003624:	0001c517          	auipc	a0,0x1c
    80003628:	1a450513          	addi	a0,a0,420 # 8001f7c8 <itable>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	66c080e7          	jalr	1644(ra) # 80000c98 <release>
}
    80003634:	854a                	mv	a0,s2
    80003636:	70a2                	ld	ra,40(sp)
    80003638:	7402                	ld	s0,32(sp)
    8000363a:	64e2                	ld	s1,24(sp)
    8000363c:	6942                	ld	s2,16(sp)
    8000363e:	69a2                	ld	s3,8(sp)
    80003640:	6a02                	ld	s4,0(sp)
    80003642:	6145                	addi	sp,sp,48
    80003644:	8082                	ret
    panic("iget: no inodes");
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	f5a50513          	addi	a0,a0,-166 # 800085a0 <syscalls+0x140>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>

0000000080003656 <fsinit>:
fsinit(int dev) {
    80003656:	7179                	addi	sp,sp,-48
    80003658:	f406                	sd	ra,40(sp)
    8000365a:	f022                	sd	s0,32(sp)
    8000365c:	ec26                	sd	s1,24(sp)
    8000365e:	e84a                	sd	s2,16(sp)
    80003660:	e44e                	sd	s3,8(sp)
    80003662:	1800                	addi	s0,sp,48
    80003664:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003666:	4585                	li	a1,1
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	a64080e7          	jalr	-1436(ra) # 800030cc <bread>
    80003670:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003672:	0001c997          	auipc	s3,0x1c
    80003676:	13698993          	addi	s3,s3,310 # 8001f7a8 <sb>
    8000367a:	02000613          	li	a2,32
    8000367e:	05850593          	addi	a1,a0,88
    80003682:	854e                	mv	a0,s3
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	6bc080e7          	jalr	1724(ra) # 80000d40 <memmove>
  brelse(bp);
    8000368c:	8526                	mv	a0,s1
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	b6e080e7          	jalr	-1170(ra) # 800031fc <brelse>
  if(sb.magic != FSMAGIC)
    80003696:	0009a703          	lw	a4,0(s3)
    8000369a:	102037b7          	lui	a5,0x10203
    8000369e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036a2:	02f71263          	bne	a4,a5,800036c6 <fsinit+0x70>
  initlog(dev, &sb);
    800036a6:	0001c597          	auipc	a1,0x1c
    800036aa:	10258593          	addi	a1,a1,258 # 8001f7a8 <sb>
    800036ae:	854a                	mv	a0,s2
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	b4c080e7          	jalr	-1204(ra) # 800041fc <initlog>
}
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6145                	addi	sp,sp,48
    800036c4:	8082                	ret
    panic("invalid file system");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	eea50513          	addi	a0,a0,-278 # 800085b0 <syscalls+0x150>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>

00000000800036d6 <iinit>:
{
    800036d6:	7179                	addi	sp,sp,-48
    800036d8:	f406                	sd	ra,40(sp)
    800036da:	f022                	sd	s0,32(sp)
    800036dc:	ec26                	sd	s1,24(sp)
    800036de:	e84a                	sd	s2,16(sp)
    800036e0:	e44e                	sd	s3,8(sp)
    800036e2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036e4:	00005597          	auipc	a1,0x5
    800036e8:	ee458593          	addi	a1,a1,-284 # 800085c8 <syscalls+0x168>
    800036ec:	0001c517          	auipc	a0,0x1c
    800036f0:	0dc50513          	addi	a0,a0,220 # 8001f7c8 <itable>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	460080e7          	jalr	1120(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036fc:	0001c497          	auipc	s1,0x1c
    80003700:	0f448493          	addi	s1,s1,244 # 8001f7f0 <itable+0x28>
    80003704:	0001e997          	auipc	s3,0x1e
    80003708:	b7c98993          	addi	s3,s3,-1156 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000370c:	00005917          	auipc	s2,0x5
    80003710:	ec490913          	addi	s2,s2,-316 # 800085d0 <syscalls+0x170>
    80003714:	85ca                	mv	a1,s2
    80003716:	8526                	mv	a0,s1
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	e46080e7          	jalr	-442(ra) # 8000455e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003720:	08848493          	addi	s1,s1,136
    80003724:	ff3498e3          	bne	s1,s3,80003714 <iinit+0x3e>
}
    80003728:	70a2                	ld	ra,40(sp)
    8000372a:	7402                	ld	s0,32(sp)
    8000372c:	64e2                	ld	s1,24(sp)
    8000372e:	6942                	ld	s2,16(sp)
    80003730:	69a2                	ld	s3,8(sp)
    80003732:	6145                	addi	sp,sp,48
    80003734:	8082                	ret

0000000080003736 <ialloc>:
{
    80003736:	715d                	addi	sp,sp,-80
    80003738:	e486                	sd	ra,72(sp)
    8000373a:	e0a2                	sd	s0,64(sp)
    8000373c:	fc26                	sd	s1,56(sp)
    8000373e:	f84a                	sd	s2,48(sp)
    80003740:	f44e                	sd	s3,40(sp)
    80003742:	f052                	sd	s4,32(sp)
    80003744:	ec56                	sd	s5,24(sp)
    80003746:	e85a                	sd	s6,16(sp)
    80003748:	e45e                	sd	s7,8(sp)
    8000374a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000374c:	0001c717          	auipc	a4,0x1c
    80003750:	06872703          	lw	a4,104(a4) # 8001f7b4 <sb+0xc>
    80003754:	4785                	li	a5,1
    80003756:	04e7fa63          	bgeu	a5,a4,800037aa <ialloc+0x74>
    8000375a:	8aaa                	mv	s5,a0
    8000375c:	8bae                	mv	s7,a1
    8000375e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003760:	0001ca17          	auipc	s4,0x1c
    80003764:	048a0a13          	addi	s4,s4,72 # 8001f7a8 <sb>
    80003768:	00048b1b          	sext.w	s6,s1
    8000376c:	0044d593          	srli	a1,s1,0x4
    80003770:	018a2783          	lw	a5,24(s4)
    80003774:	9dbd                	addw	a1,a1,a5
    80003776:	8556                	mv	a0,s5
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	954080e7          	jalr	-1708(ra) # 800030cc <bread>
    80003780:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003782:	05850993          	addi	s3,a0,88
    80003786:	00f4f793          	andi	a5,s1,15
    8000378a:	079a                	slli	a5,a5,0x6
    8000378c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000378e:	00099783          	lh	a5,0(s3)
    80003792:	c785                	beqz	a5,800037ba <ialloc+0x84>
    brelse(bp);
    80003794:	00000097          	auipc	ra,0x0
    80003798:	a68080e7          	jalr	-1432(ra) # 800031fc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000379c:	0485                	addi	s1,s1,1
    8000379e:	00ca2703          	lw	a4,12(s4)
    800037a2:	0004879b          	sext.w	a5,s1
    800037a6:	fce7e1e3          	bltu	a5,a4,80003768 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037aa:	00005517          	auipc	a0,0x5
    800037ae:	e2e50513          	addi	a0,a0,-466 # 800085d8 <syscalls+0x178>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037ba:	04000613          	li	a2,64
    800037be:	4581                	li	a1,0
    800037c0:	854e                	mv	a0,s3
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	51e080e7          	jalr	1310(ra) # 80000ce0 <memset>
      dip->type = type;
    800037ca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ce:	854a                	mv	a0,s2
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	ca8080e7          	jalr	-856(ra) # 80004478 <log_write>
      brelse(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00000097          	auipc	ra,0x0
    800037de:	a22080e7          	jalr	-1502(ra) # 800031fc <brelse>
      return iget(dev, inum);
    800037e2:	85da                	mv	a1,s6
    800037e4:	8556                	mv	a0,s5
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	db4080e7          	jalr	-588(ra) # 8000359a <iget>
}
    800037ee:	60a6                	ld	ra,72(sp)
    800037f0:	6406                	ld	s0,64(sp)
    800037f2:	74e2                	ld	s1,56(sp)
    800037f4:	7942                	ld	s2,48(sp)
    800037f6:	79a2                	ld	s3,40(sp)
    800037f8:	7a02                	ld	s4,32(sp)
    800037fa:	6ae2                	ld	s5,24(sp)
    800037fc:	6b42                	ld	s6,16(sp)
    800037fe:	6ba2                	ld	s7,8(sp)
    80003800:	6161                	addi	sp,sp,80
    80003802:	8082                	ret

0000000080003804 <iupdate>:
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
    80003810:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003812:	415c                	lw	a5,4(a0)
    80003814:	0047d79b          	srliw	a5,a5,0x4
    80003818:	0001c597          	auipc	a1,0x1c
    8000381c:	fa85a583          	lw	a1,-88(a1) # 8001f7c0 <sb+0x18>
    80003820:	9dbd                	addw	a1,a1,a5
    80003822:	4108                	lw	a0,0(a0)
    80003824:	00000097          	auipc	ra,0x0
    80003828:	8a8080e7          	jalr	-1880(ra) # 800030cc <bread>
    8000382c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382e:	05850793          	addi	a5,a0,88
    80003832:	40c8                	lw	a0,4(s1)
    80003834:	893d                	andi	a0,a0,15
    80003836:	051a                	slli	a0,a0,0x6
    80003838:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000383a:	04449703          	lh	a4,68(s1)
    8000383e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003842:	04649703          	lh	a4,70(s1)
    80003846:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000384a:	04849703          	lh	a4,72(s1)
    8000384e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003852:	04a49703          	lh	a4,74(s1)
    80003856:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000385a:	44f8                	lw	a4,76(s1)
    8000385c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000385e:	03400613          	li	a2,52
    80003862:	05048593          	addi	a1,s1,80
    80003866:	0531                	addi	a0,a0,12
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	4d8080e7          	jalr	1240(ra) # 80000d40 <memmove>
  log_write(bp);
    80003870:	854a                	mv	a0,s2
    80003872:	00001097          	auipc	ra,0x1
    80003876:	c06080e7          	jalr	-1018(ra) # 80004478 <log_write>
  brelse(bp);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	980080e7          	jalr	-1664(ra) # 800031fc <brelse>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6902                	ld	s2,0(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret

0000000080003890 <idup>:
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	1000                	addi	s0,sp,32
    8000389a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	f2c50513          	addi	a0,a0,-212 # 8001f7c8 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  ip->ref++;
    800038ac:	449c                	lw	a5,8(s1)
    800038ae:	2785                	addiw	a5,a5,1
    800038b0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038b2:	0001c517          	auipc	a0,0x1c
    800038b6:	f1650513          	addi	a0,a0,-234 # 8001f7c8 <itable>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	3de080e7          	jalr	990(ra) # 80000c98 <release>
}
    800038c2:	8526                	mv	a0,s1
    800038c4:	60e2                	ld	ra,24(sp)
    800038c6:	6442                	ld	s0,16(sp)
    800038c8:	64a2                	ld	s1,8(sp)
    800038ca:	6105                	addi	sp,sp,32
    800038cc:	8082                	ret

00000000800038ce <ilock>:
{
    800038ce:	1101                	addi	sp,sp,-32
    800038d0:	ec06                	sd	ra,24(sp)
    800038d2:	e822                	sd	s0,16(sp)
    800038d4:	e426                	sd	s1,8(sp)
    800038d6:	e04a                	sd	s2,0(sp)
    800038d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038da:	c115                	beqz	a0,800038fe <ilock+0x30>
    800038dc:	84aa                	mv	s1,a0
    800038de:	451c                	lw	a5,8(a0)
    800038e0:	00f05f63          	blez	a5,800038fe <ilock+0x30>
  acquiresleep(&ip->lock);
    800038e4:	0541                	addi	a0,a0,16
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	cb2080e7          	jalr	-846(ra) # 80004598 <acquiresleep>
  if(ip->valid == 0){
    800038ee:	40bc                	lw	a5,64(s1)
    800038f0:	cf99                	beqz	a5,8000390e <ilock+0x40>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6902                	ld	s2,0(sp)
    800038fa:	6105                	addi	sp,sp,32
    800038fc:	8082                	ret
    panic("ilock");
    800038fe:	00005517          	auipc	a0,0x5
    80003902:	cf250513          	addi	a0,a0,-782 # 800085f0 <syscalls+0x190>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	c38080e7          	jalr	-968(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000390e:	40dc                	lw	a5,4(s1)
    80003910:	0047d79b          	srliw	a5,a5,0x4
    80003914:	0001c597          	auipc	a1,0x1c
    80003918:	eac5a583          	lw	a1,-340(a1) # 8001f7c0 <sb+0x18>
    8000391c:	9dbd                	addw	a1,a1,a5
    8000391e:	4088                	lw	a0,0(s1)
    80003920:	fffff097          	auipc	ra,0xfffff
    80003924:	7ac080e7          	jalr	1964(ra) # 800030cc <bread>
    80003928:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000392a:	05850593          	addi	a1,a0,88
    8000392e:	40dc                	lw	a5,4(s1)
    80003930:	8bbd                	andi	a5,a5,15
    80003932:	079a                	slli	a5,a5,0x6
    80003934:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003936:	00059783          	lh	a5,0(a1)
    8000393a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000393e:	00259783          	lh	a5,2(a1)
    80003942:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003946:	00459783          	lh	a5,4(a1)
    8000394a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000394e:	00659783          	lh	a5,6(a1)
    80003952:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003956:	459c                	lw	a5,8(a1)
    80003958:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000395a:	03400613          	li	a2,52
    8000395e:	05b1                	addi	a1,a1,12
    80003960:	05048513          	addi	a0,s1,80
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	3dc080e7          	jalr	988(ra) # 80000d40 <memmove>
    brelse(bp);
    8000396c:	854a                	mv	a0,s2
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	88e080e7          	jalr	-1906(ra) # 800031fc <brelse>
    ip->valid = 1;
    80003976:	4785                	li	a5,1
    80003978:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000397a:	04449783          	lh	a5,68(s1)
    8000397e:	fbb5                	bnez	a5,800038f2 <ilock+0x24>
      panic("ilock: no type");
    80003980:	00005517          	auipc	a0,0x5
    80003984:	c7850513          	addi	a0,a0,-904 # 800085f8 <syscalls+0x198>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>

0000000080003990 <iunlock>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	e04a                	sd	s2,0(sp)
    8000399a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000399c:	c905                	beqz	a0,800039cc <iunlock+0x3c>
    8000399e:	84aa                	mv	s1,a0
    800039a0:	01050913          	addi	s2,a0,16
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	c8c080e7          	jalr	-884(ra) # 80004632 <holdingsleep>
    800039ae:	cd19                	beqz	a0,800039cc <iunlock+0x3c>
    800039b0:	449c                	lw	a5,8(s1)
    800039b2:	00f05d63          	blez	a5,800039cc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039b6:	854a                	mv	a0,s2
    800039b8:	00001097          	auipc	ra,0x1
    800039bc:	c36080e7          	jalr	-970(ra) # 800045ee <releasesleep>
}
    800039c0:	60e2                	ld	ra,24(sp)
    800039c2:	6442                	ld	s0,16(sp)
    800039c4:	64a2                	ld	s1,8(sp)
    800039c6:	6902                	ld	s2,0(sp)
    800039c8:	6105                	addi	sp,sp,32
    800039ca:	8082                	ret
    panic("iunlock");
    800039cc:	00005517          	auipc	a0,0x5
    800039d0:	c3c50513          	addi	a0,a0,-964 # 80008608 <syscalls+0x1a8>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	b6a080e7          	jalr	-1174(ra) # 8000053e <panic>

00000000800039dc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039dc:	7179                	addi	sp,sp,-48
    800039de:	f406                	sd	ra,40(sp)
    800039e0:	f022                	sd	s0,32(sp)
    800039e2:	ec26                	sd	s1,24(sp)
    800039e4:	e84a                	sd	s2,16(sp)
    800039e6:	e44e                	sd	s3,8(sp)
    800039e8:	e052                	sd	s4,0(sp)
    800039ea:	1800                	addi	s0,sp,48
    800039ec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039ee:	05050493          	addi	s1,a0,80
    800039f2:	08050913          	addi	s2,a0,128
    800039f6:	a021                	j	800039fe <itrunc+0x22>
    800039f8:	0491                	addi	s1,s1,4
    800039fa:	01248d63          	beq	s1,s2,80003a14 <itrunc+0x38>
    if(ip->addrs[i]){
    800039fe:	408c                	lw	a1,0(s1)
    80003a00:	dde5                	beqz	a1,800039f8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a02:	0009a503          	lw	a0,0(s3)
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	90c080e7          	jalr	-1780(ra) # 80003312 <bfree>
      ip->addrs[i] = 0;
    80003a0e:	0004a023          	sw	zero,0(s1)
    80003a12:	b7dd                	j	800039f8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a14:	0809a583          	lw	a1,128(s3)
    80003a18:	e185                	bnez	a1,80003a38 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a1a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a1e:	854e                	mv	a0,s3
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	de4080e7          	jalr	-540(ra) # 80003804 <iupdate>
}
    80003a28:	70a2                	ld	ra,40(sp)
    80003a2a:	7402                	ld	s0,32(sp)
    80003a2c:	64e2                	ld	s1,24(sp)
    80003a2e:	6942                	ld	s2,16(sp)
    80003a30:	69a2                	ld	s3,8(sp)
    80003a32:	6a02                	ld	s4,0(sp)
    80003a34:	6145                	addi	sp,sp,48
    80003a36:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a38:	0009a503          	lw	a0,0(s3)
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	690080e7          	jalr	1680(ra) # 800030cc <bread>
    80003a44:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a46:	05850493          	addi	s1,a0,88
    80003a4a:	45850913          	addi	s2,a0,1112
    80003a4e:	a811                	j	80003a62 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a50:	0009a503          	lw	a0,0(s3)
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	8be080e7          	jalr	-1858(ra) # 80003312 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a5c:	0491                	addi	s1,s1,4
    80003a5e:	01248563          	beq	s1,s2,80003a68 <itrunc+0x8c>
      if(a[j])
    80003a62:	408c                	lw	a1,0(s1)
    80003a64:	dde5                	beqz	a1,80003a5c <itrunc+0x80>
    80003a66:	b7ed                	j	80003a50 <itrunc+0x74>
    brelse(bp);
    80003a68:	8552                	mv	a0,s4
    80003a6a:	fffff097          	auipc	ra,0xfffff
    80003a6e:	792080e7          	jalr	1938(ra) # 800031fc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a72:	0809a583          	lw	a1,128(s3)
    80003a76:	0009a503          	lw	a0,0(s3)
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	898080e7          	jalr	-1896(ra) # 80003312 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a82:	0809a023          	sw	zero,128(s3)
    80003a86:	bf51                	j	80003a1a <itrunc+0x3e>

0000000080003a88 <iput>:
{
    80003a88:	1101                	addi	sp,sp,-32
    80003a8a:	ec06                	sd	ra,24(sp)
    80003a8c:	e822                	sd	s0,16(sp)
    80003a8e:	e426                	sd	s1,8(sp)
    80003a90:	e04a                	sd	s2,0(sp)
    80003a92:	1000                	addi	s0,sp,32
    80003a94:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a96:	0001c517          	auipc	a0,0x1c
    80003a9a:	d3250513          	addi	a0,a0,-718 # 8001f7c8 <itable>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa6:	4498                	lw	a4,8(s1)
    80003aa8:	4785                	li	a5,1
    80003aaa:	02f70363          	beq	a4,a5,80003ad0 <iput+0x48>
  ip->ref--;
    80003aae:	449c                	lw	a5,8(s1)
    80003ab0:	37fd                	addiw	a5,a5,-1
    80003ab2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ab4:	0001c517          	auipc	a0,0x1c
    80003ab8:	d1450513          	addi	a0,a0,-748 # 8001f7c8 <itable>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	1dc080e7          	jalr	476(ra) # 80000c98 <release>
}
    80003ac4:	60e2                	ld	ra,24(sp)
    80003ac6:	6442                	ld	s0,16(sp)
    80003ac8:	64a2                	ld	s1,8(sp)
    80003aca:	6902                	ld	s2,0(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad0:	40bc                	lw	a5,64(s1)
    80003ad2:	dff1                	beqz	a5,80003aae <iput+0x26>
    80003ad4:	04a49783          	lh	a5,74(s1)
    80003ad8:	fbf9                	bnez	a5,80003aae <iput+0x26>
    acquiresleep(&ip->lock);
    80003ada:	01048913          	addi	s2,s1,16
    80003ade:	854a                	mv	a0,s2
    80003ae0:	00001097          	auipc	ra,0x1
    80003ae4:	ab8080e7          	jalr	-1352(ra) # 80004598 <acquiresleep>
    release(&itable.lock);
    80003ae8:	0001c517          	auipc	a0,0x1c
    80003aec:	ce050513          	addi	a0,a0,-800 # 8001f7c8 <itable>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	1a8080e7          	jalr	424(ra) # 80000c98 <release>
    itrunc(ip);
    80003af8:	8526                	mv	a0,s1
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	ee2080e7          	jalr	-286(ra) # 800039dc <itrunc>
    ip->type = 0;
    80003b02:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b06:	8526                	mv	a0,s1
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	cfc080e7          	jalr	-772(ra) # 80003804 <iupdate>
    ip->valid = 0;
    80003b10:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b14:	854a                	mv	a0,s2
    80003b16:	00001097          	auipc	ra,0x1
    80003b1a:	ad8080e7          	jalr	-1320(ra) # 800045ee <releasesleep>
    acquire(&itable.lock);
    80003b1e:	0001c517          	auipc	a0,0x1c
    80003b22:	caa50513          	addi	a0,a0,-854 # 8001f7c8 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
    80003b2e:	b741                	j	80003aae <iput+0x26>

0000000080003b30 <iunlockput>:
{
    80003b30:	1101                	addi	sp,sp,-32
    80003b32:	ec06                	sd	ra,24(sp)
    80003b34:	e822                	sd	s0,16(sp)
    80003b36:	e426                	sd	s1,8(sp)
    80003b38:	1000                	addi	s0,sp,32
    80003b3a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	e54080e7          	jalr	-428(ra) # 80003990 <iunlock>
  iput(ip);
    80003b44:	8526                	mv	a0,s1
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	f42080e7          	jalr	-190(ra) # 80003a88 <iput>
}
    80003b4e:	60e2                	ld	ra,24(sp)
    80003b50:	6442                	ld	s0,16(sp)
    80003b52:	64a2                	ld	s1,8(sp)
    80003b54:	6105                	addi	sp,sp,32
    80003b56:	8082                	ret

0000000080003b58 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b58:	1141                	addi	sp,sp,-16
    80003b5a:	e422                	sd	s0,8(sp)
    80003b5c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b5e:	411c                	lw	a5,0(a0)
    80003b60:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b62:	415c                	lw	a5,4(a0)
    80003b64:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b66:	04451783          	lh	a5,68(a0)
    80003b6a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b6e:	04a51783          	lh	a5,74(a0)
    80003b72:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b76:	04c56783          	lwu	a5,76(a0)
    80003b7a:	e99c                	sd	a5,16(a1)
}
    80003b7c:	6422                	ld	s0,8(sp)
    80003b7e:	0141                	addi	sp,sp,16
    80003b80:	8082                	ret

0000000080003b82 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b82:	457c                	lw	a5,76(a0)
    80003b84:	0ed7e963          	bltu	a5,a3,80003c76 <readi+0xf4>
{
    80003b88:	7159                	addi	sp,sp,-112
    80003b8a:	f486                	sd	ra,104(sp)
    80003b8c:	f0a2                	sd	s0,96(sp)
    80003b8e:	eca6                	sd	s1,88(sp)
    80003b90:	e8ca                	sd	s2,80(sp)
    80003b92:	e4ce                	sd	s3,72(sp)
    80003b94:	e0d2                	sd	s4,64(sp)
    80003b96:	fc56                	sd	s5,56(sp)
    80003b98:	f85a                	sd	s6,48(sp)
    80003b9a:	f45e                	sd	s7,40(sp)
    80003b9c:	f062                	sd	s8,32(sp)
    80003b9e:	ec66                	sd	s9,24(sp)
    80003ba0:	e86a                	sd	s10,16(sp)
    80003ba2:	e46e                	sd	s11,8(sp)
    80003ba4:	1880                	addi	s0,sp,112
    80003ba6:	8baa                	mv	s7,a0
    80003ba8:	8c2e                	mv	s8,a1
    80003baa:	8ab2                	mv	s5,a2
    80003bac:	84b6                	mv	s1,a3
    80003bae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb0:	9f35                	addw	a4,a4,a3
    return 0;
    80003bb2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bb4:	0ad76063          	bltu	a4,a3,80003c54 <readi+0xd2>
  if(off + n > ip->size)
    80003bb8:	00e7f463          	bgeu	a5,a4,80003bc0 <readi+0x3e>
    n = ip->size - off;
    80003bbc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc0:	0a0b0963          	beqz	s6,80003c72 <readi+0xf0>
    80003bc4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bca:	5cfd                	li	s9,-1
    80003bcc:	a82d                	j	80003c06 <readi+0x84>
    80003bce:	020a1d93          	slli	s11,s4,0x20
    80003bd2:	020ddd93          	srli	s11,s11,0x20
    80003bd6:	05890613          	addi	a2,s2,88
    80003bda:	86ee                	mv	a3,s11
    80003bdc:	963a                	add	a2,a2,a4
    80003bde:	85d6                	mv	a1,s5
    80003be0:	8562                	mv	a0,s8
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	a92080e7          	jalr	-1390(ra) # 80002674 <either_copyout>
    80003bea:	05950d63          	beq	a0,s9,80003c44 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	60c080e7          	jalr	1548(ra) # 800031fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf8:	013a09bb          	addw	s3,s4,s3
    80003bfc:	009a04bb          	addw	s1,s4,s1
    80003c00:	9aee                	add	s5,s5,s11
    80003c02:	0569f763          	bgeu	s3,s6,80003c50 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c06:	000ba903          	lw	s2,0(s7)
    80003c0a:	00a4d59b          	srliw	a1,s1,0xa
    80003c0e:	855e                	mv	a0,s7
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	8b0080e7          	jalr	-1872(ra) # 800034c0 <bmap>
    80003c18:	0005059b          	sext.w	a1,a0
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	4ae080e7          	jalr	1198(ra) # 800030cc <bread>
    80003c26:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c28:	3ff4f713          	andi	a4,s1,1023
    80003c2c:	40ed07bb          	subw	a5,s10,a4
    80003c30:	413b06bb          	subw	a3,s6,s3
    80003c34:	8a3e                	mv	s4,a5
    80003c36:	2781                	sext.w	a5,a5
    80003c38:	0006861b          	sext.w	a2,a3
    80003c3c:	f8f679e3          	bgeu	a2,a5,80003bce <readi+0x4c>
    80003c40:	8a36                	mv	s4,a3
    80003c42:	b771                	j	80003bce <readi+0x4c>
      brelse(bp);
    80003c44:	854a                	mv	a0,s2
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	5b6080e7          	jalr	1462(ra) # 800031fc <brelse>
      tot = -1;
    80003c4e:	59fd                	li	s3,-1
  }
  return tot;
    80003c50:	0009851b          	sext.w	a0,s3
}
    80003c54:	70a6                	ld	ra,104(sp)
    80003c56:	7406                	ld	s0,96(sp)
    80003c58:	64e6                	ld	s1,88(sp)
    80003c5a:	6946                	ld	s2,80(sp)
    80003c5c:	69a6                	ld	s3,72(sp)
    80003c5e:	6a06                	ld	s4,64(sp)
    80003c60:	7ae2                	ld	s5,56(sp)
    80003c62:	7b42                	ld	s6,48(sp)
    80003c64:	7ba2                	ld	s7,40(sp)
    80003c66:	7c02                	ld	s8,32(sp)
    80003c68:	6ce2                	ld	s9,24(sp)
    80003c6a:	6d42                	ld	s10,16(sp)
    80003c6c:	6da2                	ld	s11,8(sp)
    80003c6e:	6165                	addi	sp,sp,112
    80003c70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c72:	89da                	mv	s3,s6
    80003c74:	bff1                	j	80003c50 <readi+0xce>
    return 0;
    80003c76:	4501                	li	a0,0
}
    80003c78:	8082                	ret

0000000080003c7a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7a:	457c                	lw	a5,76(a0)
    80003c7c:	10d7e863          	bltu	a5,a3,80003d8c <writei+0x112>
{
    80003c80:	7159                	addi	sp,sp,-112
    80003c82:	f486                	sd	ra,104(sp)
    80003c84:	f0a2                	sd	s0,96(sp)
    80003c86:	eca6                	sd	s1,88(sp)
    80003c88:	e8ca                	sd	s2,80(sp)
    80003c8a:	e4ce                	sd	s3,72(sp)
    80003c8c:	e0d2                	sd	s4,64(sp)
    80003c8e:	fc56                	sd	s5,56(sp)
    80003c90:	f85a                	sd	s6,48(sp)
    80003c92:	f45e                	sd	s7,40(sp)
    80003c94:	f062                	sd	s8,32(sp)
    80003c96:	ec66                	sd	s9,24(sp)
    80003c98:	e86a                	sd	s10,16(sp)
    80003c9a:	e46e                	sd	s11,8(sp)
    80003c9c:	1880                	addi	s0,sp,112
    80003c9e:	8b2a                	mv	s6,a0
    80003ca0:	8c2e                	mv	s8,a1
    80003ca2:	8ab2                	mv	s5,a2
    80003ca4:	8936                	mv	s2,a3
    80003ca6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ca8:	00e687bb          	addw	a5,a3,a4
    80003cac:	0ed7e263          	bltu	a5,a3,80003d90 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cb0:	00043737          	lui	a4,0x43
    80003cb4:	0ef76063          	bltu	a4,a5,80003d94 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb8:	0c0b8863          	beqz	s7,80003d88 <writei+0x10e>
    80003cbc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cbe:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cc2:	5cfd                	li	s9,-1
    80003cc4:	a091                	j	80003d08 <writei+0x8e>
    80003cc6:	02099d93          	slli	s11,s3,0x20
    80003cca:	020ddd93          	srli	s11,s11,0x20
    80003cce:	05848513          	addi	a0,s1,88
    80003cd2:	86ee                	mv	a3,s11
    80003cd4:	8656                	mv	a2,s5
    80003cd6:	85e2                	mv	a1,s8
    80003cd8:	953a                	add	a0,a0,a4
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	9f0080e7          	jalr	-1552(ra) # 800026ca <either_copyin>
    80003ce2:	07950263          	beq	a0,s9,80003d46 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ce6:	8526                	mv	a0,s1
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	790080e7          	jalr	1936(ra) # 80004478 <log_write>
    brelse(bp);
    80003cf0:	8526                	mv	a0,s1
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	50a080e7          	jalr	1290(ra) # 800031fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfa:	01498a3b          	addw	s4,s3,s4
    80003cfe:	0129893b          	addw	s2,s3,s2
    80003d02:	9aee                	add	s5,s5,s11
    80003d04:	057a7663          	bgeu	s4,s7,80003d50 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d08:	000b2483          	lw	s1,0(s6)
    80003d0c:	00a9559b          	srliw	a1,s2,0xa
    80003d10:	855a                	mv	a0,s6
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	7ae080e7          	jalr	1966(ra) # 800034c0 <bmap>
    80003d1a:	0005059b          	sext.w	a1,a0
    80003d1e:	8526                	mv	a0,s1
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	3ac080e7          	jalr	940(ra) # 800030cc <bread>
    80003d28:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2a:	3ff97713          	andi	a4,s2,1023
    80003d2e:	40ed07bb          	subw	a5,s10,a4
    80003d32:	414b86bb          	subw	a3,s7,s4
    80003d36:	89be                	mv	s3,a5
    80003d38:	2781                	sext.w	a5,a5
    80003d3a:	0006861b          	sext.w	a2,a3
    80003d3e:	f8f674e3          	bgeu	a2,a5,80003cc6 <writei+0x4c>
    80003d42:	89b6                	mv	s3,a3
    80003d44:	b749                	j	80003cc6 <writei+0x4c>
      brelse(bp);
    80003d46:	8526                	mv	a0,s1
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	4b4080e7          	jalr	1204(ra) # 800031fc <brelse>
  }

  if(off > ip->size)
    80003d50:	04cb2783          	lw	a5,76(s6)
    80003d54:	0127f463          	bgeu	a5,s2,80003d5c <writei+0xe2>
    ip->size = off;
    80003d58:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d5c:	855a                	mv	a0,s6
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	aa6080e7          	jalr	-1370(ra) # 80003804 <iupdate>

  return tot;
    80003d66:	000a051b          	sext.w	a0,s4
}
    80003d6a:	70a6                	ld	ra,104(sp)
    80003d6c:	7406                	ld	s0,96(sp)
    80003d6e:	64e6                	ld	s1,88(sp)
    80003d70:	6946                	ld	s2,80(sp)
    80003d72:	69a6                	ld	s3,72(sp)
    80003d74:	6a06                	ld	s4,64(sp)
    80003d76:	7ae2                	ld	s5,56(sp)
    80003d78:	7b42                	ld	s6,48(sp)
    80003d7a:	7ba2                	ld	s7,40(sp)
    80003d7c:	7c02                	ld	s8,32(sp)
    80003d7e:	6ce2                	ld	s9,24(sp)
    80003d80:	6d42                	ld	s10,16(sp)
    80003d82:	6da2                	ld	s11,8(sp)
    80003d84:	6165                	addi	sp,sp,112
    80003d86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d88:	8a5e                	mv	s4,s7
    80003d8a:	bfc9                	j	80003d5c <writei+0xe2>
    return -1;
    80003d8c:	557d                	li	a0,-1
}
    80003d8e:	8082                	ret
    return -1;
    80003d90:	557d                	li	a0,-1
    80003d92:	bfe1                	j	80003d6a <writei+0xf0>
    return -1;
    80003d94:	557d                	li	a0,-1
    80003d96:	bfd1                	j	80003d6a <writei+0xf0>

0000000080003d98 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d98:	1141                	addi	sp,sp,-16
    80003d9a:	e406                	sd	ra,8(sp)
    80003d9c:	e022                	sd	s0,0(sp)
    80003d9e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003da0:	4639                	li	a2,14
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	016080e7          	jalr	22(ra) # 80000db8 <strncmp>
}
    80003daa:	60a2                	ld	ra,8(sp)
    80003dac:	6402                	ld	s0,0(sp)
    80003dae:	0141                	addi	sp,sp,16
    80003db0:	8082                	ret

0000000080003db2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003db2:	7139                	addi	sp,sp,-64
    80003db4:	fc06                	sd	ra,56(sp)
    80003db6:	f822                	sd	s0,48(sp)
    80003db8:	f426                	sd	s1,40(sp)
    80003dba:	f04a                	sd	s2,32(sp)
    80003dbc:	ec4e                	sd	s3,24(sp)
    80003dbe:	e852                	sd	s4,16(sp)
    80003dc0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dc2:	04451703          	lh	a4,68(a0)
    80003dc6:	4785                	li	a5,1
    80003dc8:	00f71a63          	bne	a4,a5,80003ddc <dirlookup+0x2a>
    80003dcc:	892a                	mv	s2,a0
    80003dce:	89ae                	mv	s3,a1
    80003dd0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd2:	457c                	lw	a5,76(a0)
    80003dd4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dd6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd8:	e79d                	bnez	a5,80003e06 <dirlookup+0x54>
    80003dda:	a8a5                	j	80003e52 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ddc:	00005517          	auipc	a0,0x5
    80003de0:	83450513          	addi	a0,a0,-1996 # 80008610 <syscalls+0x1b0>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	75a080e7          	jalr	1882(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	83c50513          	addi	a0,a0,-1988 # 80008628 <syscalls+0x1c8>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	24c1                	addiw	s1,s1,16
    80003dfe:	04c92783          	lw	a5,76(s2)
    80003e02:	04f4f763          	bgeu	s1,a5,80003e50 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e06:	4741                	li	a4,16
    80003e08:	86a6                	mv	a3,s1
    80003e0a:	fc040613          	addi	a2,s0,-64
    80003e0e:	4581                	li	a1,0
    80003e10:	854a                	mv	a0,s2
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	d70080e7          	jalr	-656(ra) # 80003b82 <readi>
    80003e1a:	47c1                	li	a5,16
    80003e1c:	fcf518e3          	bne	a0,a5,80003dec <dirlookup+0x3a>
    if(de.inum == 0)
    80003e20:	fc045783          	lhu	a5,-64(s0)
    80003e24:	dfe1                	beqz	a5,80003dfc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e26:	fc240593          	addi	a1,s0,-62
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	f6c080e7          	jalr	-148(ra) # 80003d98 <namecmp>
    80003e34:	f561                	bnez	a0,80003dfc <dirlookup+0x4a>
      if(poff)
    80003e36:	000a0463          	beqz	s4,80003e3e <dirlookup+0x8c>
        *poff = off;
    80003e3a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e3e:	fc045583          	lhu	a1,-64(s0)
    80003e42:	00092503          	lw	a0,0(s2)
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	754080e7          	jalr	1876(ra) # 8000359a <iget>
    80003e4e:	a011                	j	80003e52 <dirlookup+0xa0>
  return 0;
    80003e50:	4501                	li	a0,0
}
    80003e52:	70e2                	ld	ra,56(sp)
    80003e54:	7442                	ld	s0,48(sp)
    80003e56:	74a2                	ld	s1,40(sp)
    80003e58:	7902                	ld	s2,32(sp)
    80003e5a:	69e2                	ld	s3,24(sp)
    80003e5c:	6a42                	ld	s4,16(sp)
    80003e5e:	6121                	addi	sp,sp,64
    80003e60:	8082                	ret

0000000080003e62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e62:	711d                	addi	sp,sp,-96
    80003e64:	ec86                	sd	ra,88(sp)
    80003e66:	e8a2                	sd	s0,80(sp)
    80003e68:	e4a6                	sd	s1,72(sp)
    80003e6a:	e0ca                	sd	s2,64(sp)
    80003e6c:	fc4e                	sd	s3,56(sp)
    80003e6e:	f852                	sd	s4,48(sp)
    80003e70:	f456                	sd	s5,40(sp)
    80003e72:	f05a                	sd	s6,32(sp)
    80003e74:	ec5e                	sd	s7,24(sp)
    80003e76:	e862                	sd	s8,16(sp)
    80003e78:	e466                	sd	s9,8(sp)
    80003e7a:	1080                	addi	s0,sp,96
    80003e7c:	84aa                	mv	s1,a0
    80003e7e:	8b2e                	mv	s6,a1
    80003e80:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e82:	00054703          	lbu	a4,0(a0)
    80003e86:	02f00793          	li	a5,47
    80003e8a:	02f70363          	beq	a4,a5,80003eb0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e8e:	ffffe097          	auipc	ra,0xffffe
    80003e92:	b22080e7          	jalr	-1246(ra) # 800019b0 <myproc>
    80003e96:	15053503          	ld	a0,336(a0)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	9f6080e7          	jalr	-1546(ra) # 80003890 <idup>
    80003ea2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ea4:	02f00913          	li	s2,47
  len = path - s;
    80003ea8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003eaa:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eac:	4c05                	li	s8,1
    80003eae:	a865                	j	80003f66 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003eb0:	4585                	li	a1,1
    80003eb2:	4505                	li	a0,1
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	6e6080e7          	jalr	1766(ra) # 8000359a <iget>
    80003ebc:	89aa                	mv	s3,a0
    80003ebe:	b7dd                	j	80003ea4 <namex+0x42>
      iunlockput(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	c6e080e7          	jalr	-914(ra) # 80003b30 <iunlockput>
      return 0;
    80003eca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ecc:	854e                	mv	a0,s3
    80003ece:	60e6                	ld	ra,88(sp)
    80003ed0:	6446                	ld	s0,80(sp)
    80003ed2:	64a6                	ld	s1,72(sp)
    80003ed4:	6906                	ld	s2,64(sp)
    80003ed6:	79e2                	ld	s3,56(sp)
    80003ed8:	7a42                	ld	s4,48(sp)
    80003eda:	7aa2                	ld	s5,40(sp)
    80003edc:	7b02                	ld	s6,32(sp)
    80003ede:	6be2                	ld	s7,24(sp)
    80003ee0:	6c42                	ld	s8,16(sp)
    80003ee2:	6ca2                	ld	s9,8(sp)
    80003ee4:	6125                	addi	sp,sp,96
    80003ee6:	8082                	ret
      iunlock(ip);
    80003ee8:	854e                	mv	a0,s3
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	aa6080e7          	jalr	-1370(ra) # 80003990 <iunlock>
      return ip;
    80003ef2:	bfe9                	j	80003ecc <namex+0x6a>
      iunlockput(ip);
    80003ef4:	854e                	mv	a0,s3
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	c3a080e7          	jalr	-966(ra) # 80003b30 <iunlockput>
      return 0;
    80003efe:	89d2                	mv	s3,s4
    80003f00:	b7f1                	j	80003ecc <namex+0x6a>
  len = path - s;
    80003f02:	40b48633          	sub	a2,s1,a1
    80003f06:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f0a:	094cd463          	bge	s9,s4,80003f92 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f0e:	4639                	li	a2,14
    80003f10:	8556                	mv	a0,s5
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	e2e080e7          	jalr	-466(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f1a:	0004c783          	lbu	a5,0(s1)
    80003f1e:	01279763          	bne	a5,s2,80003f2c <namex+0xca>
    path++;
    80003f22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f24:	0004c783          	lbu	a5,0(s1)
    80003f28:	ff278de3          	beq	a5,s2,80003f22 <namex+0xc0>
    ilock(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	9a0080e7          	jalr	-1632(ra) # 800038ce <ilock>
    if(ip->type != T_DIR){
    80003f36:	04499783          	lh	a5,68(s3)
    80003f3a:	f98793e3          	bne	a5,s8,80003ec0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f3e:	000b0563          	beqz	s6,80003f48 <namex+0xe6>
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	d3cd                	beqz	a5,80003ee8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f48:	865e                	mv	a2,s7
    80003f4a:	85d6                	mv	a1,s5
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	e64080e7          	jalr	-412(ra) # 80003db2 <dirlookup>
    80003f56:	8a2a                	mv	s4,a0
    80003f58:	dd51                	beqz	a0,80003ef4 <namex+0x92>
    iunlockput(ip);
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	bd4080e7          	jalr	-1068(ra) # 80003b30 <iunlockput>
    ip = next;
    80003f64:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f66:	0004c783          	lbu	a5,0(s1)
    80003f6a:	05279763          	bne	a5,s2,80003fb8 <namex+0x156>
    path++;
    80003f6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	ff278de3          	beq	a5,s2,80003f6e <namex+0x10c>
  if(*path == 0)
    80003f78:	c79d                	beqz	a5,80003fa6 <namex+0x144>
    path++;
    80003f7a:	85a6                	mv	a1,s1
  len = path - s;
    80003f7c:	8a5e                	mv	s4,s7
    80003f7e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f80:	01278963          	beq	a5,s2,80003f92 <namex+0x130>
    80003f84:	dfbd                	beqz	a5,80003f02 <namex+0xa0>
    path++;
    80003f86:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f88:	0004c783          	lbu	a5,0(s1)
    80003f8c:	ff279ce3          	bne	a5,s2,80003f84 <namex+0x122>
    80003f90:	bf8d                	j	80003f02 <namex+0xa0>
    memmove(name, s, len);
    80003f92:	2601                	sext.w	a2,a2
    80003f94:	8556                	mv	a0,s5
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	daa080e7          	jalr	-598(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f9e:	9a56                	add	s4,s4,s5
    80003fa0:	000a0023          	sb	zero,0(s4)
    80003fa4:	bf9d                	j	80003f1a <namex+0xb8>
  if(nameiparent){
    80003fa6:	f20b03e3          	beqz	s6,80003ecc <namex+0x6a>
    iput(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	adc080e7          	jalr	-1316(ra) # 80003a88 <iput>
    return 0;
    80003fb4:	4981                	li	s3,0
    80003fb6:	bf19                	j	80003ecc <namex+0x6a>
  if(*path == 0)
    80003fb8:	d7fd                	beqz	a5,80003fa6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	85a6                	mv	a1,s1
    80003fc0:	b7d1                	j	80003f84 <namex+0x122>

0000000080003fc2 <dirlink>:
{
    80003fc2:	7139                	addi	sp,sp,-64
    80003fc4:	fc06                	sd	ra,56(sp)
    80003fc6:	f822                	sd	s0,48(sp)
    80003fc8:	f426                	sd	s1,40(sp)
    80003fca:	f04a                	sd	s2,32(sp)
    80003fcc:	ec4e                	sd	s3,24(sp)
    80003fce:	e852                	sd	s4,16(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	892a                	mv	s2,a0
    80003fd4:	8a2e                	mv	s4,a1
    80003fd6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fd8:	4601                	li	a2,0
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	dd8080e7          	jalr	-552(ra) # 80003db2 <dirlookup>
    80003fe2:	e93d                	bnez	a0,80004058 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe4:	04c92483          	lw	s1,76(s2)
    80003fe8:	c49d                	beqz	s1,80004016 <dirlink+0x54>
    80003fea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fec:	4741                	li	a4,16
    80003fee:	86a6                	mv	a3,s1
    80003ff0:	fc040613          	addi	a2,s0,-64
    80003ff4:	4581                	li	a1,0
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	b8a080e7          	jalr	-1142(ra) # 80003b82 <readi>
    80004000:	47c1                	li	a5,16
    80004002:	06f51163          	bne	a0,a5,80004064 <dirlink+0xa2>
    if(de.inum == 0)
    80004006:	fc045783          	lhu	a5,-64(s0)
    8000400a:	c791                	beqz	a5,80004016 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400c:	24c1                	addiw	s1,s1,16
    8000400e:	04c92783          	lw	a5,76(s2)
    80004012:	fcf4ede3          	bltu	s1,a5,80003fec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004016:	4639                	li	a2,14
    80004018:	85d2                	mv	a1,s4
    8000401a:	fc240513          	addi	a0,s0,-62
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	dd6080e7          	jalr	-554(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004026:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402a:	4741                	li	a4,16
    8000402c:	86a6                	mv	a3,s1
    8000402e:	fc040613          	addi	a2,s0,-64
    80004032:	4581                	li	a1,0
    80004034:	854a                	mv	a0,s2
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	c44080e7          	jalr	-956(ra) # 80003c7a <writei>
    8000403e:	872a                	mv	a4,a0
    80004040:	47c1                	li	a5,16
  return 0;
    80004042:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004044:	02f71863          	bne	a4,a5,80004074 <dirlink+0xb2>
}
    80004048:	70e2                	ld	ra,56(sp)
    8000404a:	7442                	ld	s0,48(sp)
    8000404c:	74a2                	ld	s1,40(sp)
    8000404e:	7902                	ld	s2,32(sp)
    80004050:	69e2                	ld	s3,24(sp)
    80004052:	6a42                	ld	s4,16(sp)
    80004054:	6121                	addi	sp,sp,64
    80004056:	8082                	ret
    iput(ip);
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	a30080e7          	jalr	-1488(ra) # 80003a88 <iput>
    return -1;
    80004060:	557d                	li	a0,-1
    80004062:	b7dd                	j	80004048 <dirlink+0x86>
      panic("dirlink read");
    80004064:	00004517          	auipc	a0,0x4
    80004068:	5d450513          	addi	a0,a0,1492 # 80008638 <syscalls+0x1d8>
    8000406c:	ffffc097          	auipc	ra,0xffffc
    80004070:	4d2080e7          	jalr	1234(ra) # 8000053e <panic>
    panic("dirlink");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	6d450513          	addi	a0,a0,1748 # 80008748 <syscalls+0x2e8>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>

0000000080004084 <namei>:

struct inode*
namei(char *path)
{
    80004084:	1101                	addi	sp,sp,-32
    80004086:	ec06                	sd	ra,24(sp)
    80004088:	e822                	sd	s0,16(sp)
    8000408a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000408c:	fe040613          	addi	a2,s0,-32
    80004090:	4581                	li	a1,0
    80004092:	00000097          	auipc	ra,0x0
    80004096:	dd0080e7          	jalr	-560(ra) # 80003e62 <namex>
}
    8000409a:	60e2                	ld	ra,24(sp)
    8000409c:	6442                	ld	s0,16(sp)
    8000409e:	6105                	addi	sp,sp,32
    800040a0:	8082                	ret

00000000800040a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040a2:	1141                	addi	sp,sp,-16
    800040a4:	e406                	sd	ra,8(sp)
    800040a6:	e022                	sd	s0,0(sp)
    800040a8:	0800                	addi	s0,sp,16
    800040aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040ac:	4585                	li	a1,1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	db4080e7          	jalr	-588(ra) # 80003e62 <namex>
}
    800040b6:	60a2                	ld	ra,8(sp)
    800040b8:	6402                	ld	s0,0(sp)
    800040ba:	0141                	addi	sp,sp,16
    800040bc:	8082                	ret

00000000800040be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040be:	1101                	addi	sp,sp,-32
    800040c0:	ec06                	sd	ra,24(sp)
    800040c2:	e822                	sd	s0,16(sp)
    800040c4:	e426                	sd	s1,8(sp)
    800040c6:	e04a                	sd	s2,0(sp)
    800040c8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040ca:	0001d917          	auipc	s2,0x1d
    800040ce:	1a690913          	addi	s2,s2,422 # 80021270 <log>
    800040d2:	01892583          	lw	a1,24(s2)
    800040d6:	02892503          	lw	a0,40(s2)
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	ff2080e7          	jalr	-14(ra) # 800030cc <bread>
    800040e2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040e4:	02c92683          	lw	a3,44(s2)
    800040e8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040ea:	02d05763          	blez	a3,80004118 <write_head+0x5a>
    800040ee:	0001d797          	auipc	a5,0x1d
    800040f2:	1b278793          	addi	a5,a5,434 # 800212a0 <log+0x30>
    800040f6:	05c50713          	addi	a4,a0,92
    800040fa:	36fd                	addiw	a3,a3,-1
    800040fc:	1682                	slli	a3,a3,0x20
    800040fe:	9281                	srli	a3,a3,0x20
    80004100:	068a                	slli	a3,a3,0x2
    80004102:	0001d617          	auipc	a2,0x1d
    80004106:	1a260613          	addi	a2,a2,418 # 800212a4 <log+0x34>
    8000410a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000410c:	4390                	lw	a2,0(a5)
    8000410e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004110:	0791                	addi	a5,a5,4
    80004112:	0711                	addi	a4,a4,4
    80004114:	fed79ce3          	bne	a5,a3,8000410c <write_head+0x4e>
  }
  bwrite(buf);
    80004118:	8526                	mv	a0,s1
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	0a4080e7          	jalr	164(ra) # 800031be <bwrite>
  brelse(buf);
    80004122:	8526                	mv	a0,s1
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	0d8080e7          	jalr	216(ra) # 800031fc <brelse>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6902                	ld	s2,0(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret

0000000080004138 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004138:	0001d797          	auipc	a5,0x1d
    8000413c:	1647a783          	lw	a5,356(a5) # 8002129c <log+0x2c>
    80004140:	0af05d63          	blez	a5,800041fa <install_trans+0xc2>
{
    80004144:	7139                	addi	sp,sp,-64
    80004146:	fc06                	sd	ra,56(sp)
    80004148:	f822                	sd	s0,48(sp)
    8000414a:	f426                	sd	s1,40(sp)
    8000414c:	f04a                	sd	s2,32(sp)
    8000414e:	ec4e                	sd	s3,24(sp)
    80004150:	e852                	sd	s4,16(sp)
    80004152:	e456                	sd	s5,8(sp)
    80004154:	e05a                	sd	s6,0(sp)
    80004156:	0080                	addi	s0,sp,64
    80004158:	8b2a                	mv	s6,a0
    8000415a:	0001da97          	auipc	s5,0x1d
    8000415e:	146a8a93          	addi	s5,s5,326 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004162:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004164:	0001d997          	auipc	s3,0x1d
    80004168:	10c98993          	addi	s3,s3,268 # 80021270 <log>
    8000416c:	a035                	j	80004198 <install_trans+0x60>
      bunpin(dbuf);
    8000416e:	8526                	mv	a0,s1
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	166080e7          	jalr	358(ra) # 800032d6 <bunpin>
    brelse(lbuf);
    80004178:	854a                	mv	a0,s2
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	082080e7          	jalr	130(ra) # 800031fc <brelse>
    brelse(dbuf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	078080e7          	jalr	120(ra) # 800031fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418c:	2a05                	addiw	s4,s4,1
    8000418e:	0a91                	addi	s5,s5,4
    80004190:	02c9a783          	lw	a5,44(s3)
    80004194:	04fa5963          	bge	s4,a5,800041e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004198:	0189a583          	lw	a1,24(s3)
    8000419c:	014585bb          	addw	a1,a1,s4
    800041a0:	2585                	addiw	a1,a1,1
    800041a2:	0289a503          	lw	a0,40(s3)
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	f26080e7          	jalr	-218(ra) # 800030cc <bread>
    800041ae:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041b0:	000aa583          	lw	a1,0(s5)
    800041b4:	0289a503          	lw	a0,40(s3)
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	f14080e7          	jalr	-236(ra) # 800030cc <bread>
    800041c0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c2:	40000613          	li	a2,1024
    800041c6:	05890593          	addi	a1,s2,88
    800041ca:	05850513          	addi	a0,a0,88
    800041ce:	ffffd097          	auipc	ra,0xffffd
    800041d2:	b72080e7          	jalr	-1166(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d6:	8526                	mv	a0,s1
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	fe6080e7          	jalr	-26(ra) # 800031be <bwrite>
    if(recovering == 0)
    800041e0:	f80b1ce3          	bnez	s6,80004178 <install_trans+0x40>
    800041e4:	b769                	j	8000416e <install_trans+0x36>
}
    800041e6:	70e2                	ld	ra,56(sp)
    800041e8:	7442                	ld	s0,48(sp)
    800041ea:	74a2                	ld	s1,40(sp)
    800041ec:	7902                	ld	s2,32(sp)
    800041ee:	69e2                	ld	s3,24(sp)
    800041f0:	6a42                	ld	s4,16(sp)
    800041f2:	6aa2                	ld	s5,8(sp)
    800041f4:	6b02                	ld	s6,0(sp)
    800041f6:	6121                	addi	sp,sp,64
    800041f8:	8082                	ret
    800041fa:	8082                	ret

00000000800041fc <initlog>:
{
    800041fc:	7179                	addi	sp,sp,-48
    800041fe:	f406                	sd	ra,40(sp)
    80004200:	f022                	sd	s0,32(sp)
    80004202:	ec26                	sd	s1,24(sp)
    80004204:	e84a                	sd	s2,16(sp)
    80004206:	e44e                	sd	s3,8(sp)
    80004208:	1800                	addi	s0,sp,48
    8000420a:	892a                	mv	s2,a0
    8000420c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000420e:	0001d497          	auipc	s1,0x1d
    80004212:	06248493          	addi	s1,s1,98 # 80021270 <log>
    80004216:	00004597          	auipc	a1,0x4
    8000421a:	43258593          	addi	a1,a1,1074 # 80008648 <syscalls+0x1e8>
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	934080e7          	jalr	-1740(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004228:	0149a583          	lw	a1,20(s3)
    8000422c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000422e:	0109a783          	lw	a5,16(s3)
    80004232:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004234:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004238:	854a                	mv	a0,s2
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	e92080e7          	jalr	-366(ra) # 800030cc <bread>
  log.lh.n = lh->n;
    80004242:	4d3c                	lw	a5,88(a0)
    80004244:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004246:	02f05563          	blez	a5,80004270 <initlog+0x74>
    8000424a:	05c50713          	addi	a4,a0,92
    8000424e:	0001d697          	auipc	a3,0x1d
    80004252:	05268693          	addi	a3,a3,82 # 800212a0 <log+0x30>
    80004256:	37fd                	addiw	a5,a5,-1
    80004258:	1782                	slli	a5,a5,0x20
    8000425a:	9381                	srli	a5,a5,0x20
    8000425c:	078a                	slli	a5,a5,0x2
    8000425e:	06050613          	addi	a2,a0,96
    80004262:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004264:	4310                	lw	a2,0(a4)
    80004266:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004268:	0711                	addi	a4,a4,4
    8000426a:	0691                	addi	a3,a3,4
    8000426c:	fef71ce3          	bne	a4,a5,80004264 <initlog+0x68>
  brelse(buf);
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	f8c080e7          	jalr	-116(ra) # 800031fc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004278:	4505                	li	a0,1
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	ebe080e7          	jalr	-322(ra) # 80004138 <install_trans>
  log.lh.n = 0;
    80004282:	0001d797          	auipc	a5,0x1d
    80004286:	0007ad23          	sw	zero,26(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	e34080e7          	jalr	-460(ra) # 800040be <write_head>
}
    80004292:	70a2                	ld	ra,40(sp)
    80004294:	7402                	ld	s0,32(sp)
    80004296:	64e2                	ld	s1,24(sp)
    80004298:	6942                	ld	s2,16(sp)
    8000429a:	69a2                	ld	s3,8(sp)
    8000429c:	6145                	addi	sp,sp,48
    8000429e:	8082                	ret

00000000800042a0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	e426                	sd	s1,8(sp)
    800042a8:	e04a                	sd	s2,0(sp)
    800042aa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042ac:	0001d517          	auipc	a0,0x1d
    800042b0:	fc450513          	addi	a0,a0,-60 # 80021270 <log>
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	930080e7          	jalr	-1744(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042bc:	0001d497          	auipc	s1,0x1d
    800042c0:	fb448493          	addi	s1,s1,-76 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c4:	4979                	li	s2,30
    800042c6:	a039                	j	800042d4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042c8:	85a6                	mv	a1,s1
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	f40080e7          	jalr	-192(ra) # 8000220c <sleep>
    if(log.committing){
    800042d4:	50dc                	lw	a5,36(s1)
    800042d6:	fbed                	bnez	a5,800042c8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d8:	509c                	lw	a5,32(s1)
    800042da:	0017871b          	addiw	a4,a5,1
    800042de:	0007069b          	sext.w	a3,a4
    800042e2:	0027179b          	slliw	a5,a4,0x2
    800042e6:	9fb9                	addw	a5,a5,a4
    800042e8:	0017979b          	slliw	a5,a5,0x1
    800042ec:	54d8                	lw	a4,44(s1)
    800042ee:	9fb9                	addw	a5,a5,a4
    800042f0:	00f95963          	bge	s2,a5,80004302 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042f4:	85a6                	mv	a1,s1
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffe097          	auipc	ra,0xffffe
    800042fc:	f14080e7          	jalr	-236(ra) # 8000220c <sleep>
    80004300:	bfd1                	j	800042d4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004302:	0001d517          	auipc	a0,0x1d
    80004306:	f6e50513          	addi	a0,a0,-146 # 80021270 <log>
    8000430a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	98c080e7          	jalr	-1652(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004314:	60e2                	ld	ra,24(sp)
    80004316:	6442                	ld	s0,16(sp)
    80004318:	64a2                	ld	s1,8(sp)
    8000431a:	6902                	ld	s2,0(sp)
    8000431c:	6105                	addi	sp,sp,32
    8000431e:	8082                	ret

0000000080004320 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004320:	7139                	addi	sp,sp,-64
    80004322:	fc06                	sd	ra,56(sp)
    80004324:	f822                	sd	s0,48(sp)
    80004326:	f426                	sd	s1,40(sp)
    80004328:	f04a                	sd	s2,32(sp)
    8000432a:	ec4e                	sd	s3,24(sp)
    8000432c:	e852                	sd	s4,16(sp)
    8000432e:	e456                	sd	s5,8(sp)
    80004330:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004332:	0001d497          	auipc	s1,0x1d
    80004336:	f3e48493          	addi	s1,s1,-194 # 80021270 <log>
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004344:	509c                	lw	a5,32(s1)
    80004346:	37fd                	addiw	a5,a5,-1
    80004348:	0007891b          	sext.w	s2,a5
    8000434c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000434e:	50dc                	lw	a5,36(s1)
    80004350:	efb9                	bnez	a5,800043ae <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004352:	06091663          	bnez	s2,800043be <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004356:	0001d497          	auipc	s1,0x1d
    8000435a:	f1a48493          	addi	s1,s1,-230 # 80021270 <log>
    8000435e:	4785                	li	a5,1
    80004360:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004362:	8526                	mv	a0,s1
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000436c:	54dc                	lw	a5,44(s1)
    8000436e:	06f04763          	bgtz	a5,800043dc <end_op+0xbc>
    acquire(&log.lock);
    80004372:	0001d497          	auipc	s1,0x1d
    80004376:	efe48493          	addi	s1,s1,-258 # 80021270 <log>
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004384:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffe097          	auipc	ra,0xffffe
    8000438e:	018080e7          	jalr	24(ra) # 800023a2 <wakeup>
    release(&log.lock);
    80004392:	8526                	mv	a0,s1
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
}
    8000439c:	70e2                	ld	ra,56(sp)
    8000439e:	7442                	ld	s0,48(sp)
    800043a0:	74a2                	ld	s1,40(sp)
    800043a2:	7902                	ld	s2,32(sp)
    800043a4:	69e2                	ld	s3,24(sp)
    800043a6:	6a42                	ld	s4,16(sp)
    800043a8:	6aa2                	ld	s5,8(sp)
    800043aa:	6121                	addi	sp,sp,64
    800043ac:	8082                	ret
    panic("log.committing");
    800043ae:	00004517          	auipc	a0,0x4
    800043b2:	2a250513          	addi	a0,a0,674 # 80008650 <syscalls+0x1f0>
    800043b6:	ffffc097          	auipc	ra,0xffffc
    800043ba:	188080e7          	jalr	392(ra) # 8000053e <panic>
    wakeup(&log);
    800043be:	0001d497          	auipc	s1,0x1d
    800043c2:	eb248493          	addi	s1,s1,-334 # 80021270 <log>
    800043c6:	8526                	mv	a0,s1
    800043c8:	ffffe097          	auipc	ra,0xffffe
    800043cc:	fda080e7          	jalr	-38(ra) # 800023a2 <wakeup>
  release(&log.lock);
    800043d0:	8526                	mv	a0,s1
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  if(do_commit){
    800043da:	b7c9                	j	8000439c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043dc:	0001da97          	auipc	s5,0x1d
    800043e0:	ec4a8a93          	addi	s5,s5,-316 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043e4:	0001da17          	auipc	s4,0x1d
    800043e8:	e8ca0a13          	addi	s4,s4,-372 # 80021270 <log>
    800043ec:	018a2583          	lw	a1,24(s4)
    800043f0:	012585bb          	addw	a1,a1,s2
    800043f4:	2585                	addiw	a1,a1,1
    800043f6:	028a2503          	lw	a0,40(s4)
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	cd2080e7          	jalr	-814(ra) # 800030cc <bread>
    80004402:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004404:	000aa583          	lw	a1,0(s5)
    80004408:	028a2503          	lw	a0,40(s4)
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	cc0080e7          	jalr	-832(ra) # 800030cc <bread>
    80004414:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004416:	40000613          	li	a2,1024
    8000441a:	05850593          	addi	a1,a0,88
    8000441e:	05848513          	addi	a0,s1,88
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	91e080e7          	jalr	-1762(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	d92080e7          	jalr	-622(ra) # 800031be <bwrite>
    brelse(from);
    80004434:	854e                	mv	a0,s3
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	dc6080e7          	jalr	-570(ra) # 800031fc <brelse>
    brelse(to);
    8000443e:	8526                	mv	a0,s1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	dbc080e7          	jalr	-580(ra) # 800031fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004448:	2905                	addiw	s2,s2,1
    8000444a:	0a91                	addi	s5,s5,4
    8000444c:	02ca2783          	lw	a5,44(s4)
    80004450:	f8f94ee3          	blt	s2,a5,800043ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004454:	00000097          	auipc	ra,0x0
    80004458:	c6a080e7          	jalr	-918(ra) # 800040be <write_head>
    install_trans(0); // Now install writes to home locations
    8000445c:	4501                	li	a0,0
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	cda080e7          	jalr	-806(ra) # 80004138 <install_trans>
    log.lh.n = 0;
    80004466:	0001d797          	auipc	a5,0x1d
    8000446a:	e207ab23          	sw	zero,-458(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	c50080e7          	jalr	-944(ra) # 800040be <write_head>
    80004476:	bdf5                	j	80004372 <end_op+0x52>

0000000080004478 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004478:	1101                	addi	sp,sp,-32
    8000447a:	ec06                	sd	ra,24(sp)
    8000447c:	e822                	sd	s0,16(sp)
    8000447e:	e426                	sd	s1,8(sp)
    80004480:	e04a                	sd	s2,0(sp)
    80004482:	1000                	addi	s0,sp,32
    80004484:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004486:	0001d917          	auipc	s2,0x1d
    8000448a:	dea90913          	addi	s2,s2,-534 # 80021270 <log>
    8000448e:	854a                	mv	a0,s2
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	754080e7          	jalr	1876(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004498:	02c92603          	lw	a2,44(s2)
    8000449c:	47f5                	li	a5,29
    8000449e:	06c7c563          	blt	a5,a2,80004508 <log_write+0x90>
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	dea7a783          	lw	a5,-534(a5) # 8002128c <log+0x1c>
    800044aa:	37fd                	addiw	a5,a5,-1
    800044ac:	04f65e63          	bge	a2,a5,80004508 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044b0:	0001d797          	auipc	a5,0x1d
    800044b4:	de07a783          	lw	a5,-544(a5) # 80021290 <log+0x20>
    800044b8:	06f05063          	blez	a5,80004518 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044bc:	4781                	li	a5,0
    800044be:	06c05563          	blez	a2,80004528 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c2:	44cc                	lw	a1,12(s1)
    800044c4:	0001d717          	auipc	a4,0x1d
    800044c8:	ddc70713          	addi	a4,a4,-548 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ce:	4314                	lw	a3,0(a4)
    800044d0:	04b68c63          	beq	a3,a1,80004528 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044d4:	2785                	addiw	a5,a5,1
    800044d6:	0711                	addi	a4,a4,4
    800044d8:	fef61be3          	bne	a2,a5,800044ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044dc:	0621                	addi	a2,a2,8
    800044de:	060a                	slli	a2,a2,0x2
    800044e0:	0001d797          	auipc	a5,0x1d
    800044e4:	d9078793          	addi	a5,a5,-624 # 80021270 <log>
    800044e8:	963e                	add	a2,a2,a5
    800044ea:	44dc                	lw	a5,12(s1)
    800044ec:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ee:	8526                	mv	a0,s1
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	daa080e7          	jalr	-598(ra) # 8000329a <bpin>
    log.lh.n++;
    800044f8:	0001d717          	auipc	a4,0x1d
    800044fc:	d7870713          	addi	a4,a4,-648 # 80021270 <log>
    80004500:	575c                	lw	a5,44(a4)
    80004502:	2785                	addiw	a5,a5,1
    80004504:	d75c                	sw	a5,44(a4)
    80004506:	a835                	j	80004542 <log_write+0xca>
    panic("too big a transaction");
    80004508:	00004517          	auipc	a0,0x4
    8000450c:	15850513          	addi	a0,a0,344 # 80008660 <syscalls+0x200>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	02e080e7          	jalr	46(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004518:	00004517          	auipc	a0,0x4
    8000451c:	16050513          	addi	a0,a0,352 # 80008678 <syscalls+0x218>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	01e080e7          	jalr	30(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004528:	00878713          	addi	a4,a5,8
    8000452c:	00271693          	slli	a3,a4,0x2
    80004530:	0001d717          	auipc	a4,0x1d
    80004534:	d4070713          	addi	a4,a4,-704 # 80021270 <log>
    80004538:	9736                	add	a4,a4,a3
    8000453a:	44d4                	lw	a3,12(s1)
    8000453c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000453e:	faf608e3          	beq	a2,a5,800044ee <log_write+0x76>
  }
  release(&log.lock);
    80004542:	0001d517          	auipc	a0,0x1d
    80004546:	d2e50513          	addi	a0,a0,-722 # 80021270 <log>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	74e080e7          	jalr	1870(ra) # 80000c98 <release>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	addi	s0,sp,32
    8000456a:	84aa                	mv	s1,a0
    8000456c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000456e:	00004597          	auipc	a1,0x4
    80004572:	12a58593          	addi	a1,a1,298 # 80008698 <syscalls+0x238>
    80004576:	0521                	addi	a0,a0,8
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	5dc080e7          	jalr	1500(ra) # 80000b54 <initlock>
  lk->name = name;
    80004580:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004584:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004588:	0204a423          	sw	zero,40(s1)
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004598:	1101                	addi	sp,sp,-32
    8000459a:	ec06                	sd	ra,24(sp)
    8000459c:	e822                	sd	s0,16(sp)
    8000459e:	e426                	sd	s1,8(sp)
    800045a0:	e04a                	sd	s2,0(sp)
    800045a2:	1000                	addi	s0,sp,32
    800045a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a6:	00850913          	addi	s2,a0,8
    800045aa:	854a                	mv	a0,s2
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	638080e7          	jalr	1592(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045b4:	409c                	lw	a5,0(s1)
    800045b6:	cb89                	beqz	a5,800045c8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045b8:	85ca                	mv	a1,s2
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffe097          	auipc	ra,0xffffe
    800045c0:	c50080e7          	jalr	-944(ra) # 8000220c <sleep>
  while (lk->locked) {
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	fbed                	bnez	a5,800045b8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045c8:	4785                	li	a5,1
    800045ca:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045cc:	ffffd097          	auipc	ra,0xffffd
    800045d0:	3e4080e7          	jalr	996(ra) # 800019b0 <myproc>
    800045d4:	591c                	lw	a5,48(a0)
    800045d6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045d8:	854a                	mv	a0,s2
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
}
    800045e2:	60e2                	ld	ra,24(sp)
    800045e4:	6442                	ld	s0,16(sp)
    800045e6:	64a2                	ld	s1,8(sp)
    800045e8:	6902                	ld	s2,0(sp)
    800045ea:	6105                	addi	sp,sp,32
    800045ec:	8082                	ret

00000000800045ee <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045ee:	1101                	addi	sp,sp,-32
    800045f0:	ec06                	sd	ra,24(sp)
    800045f2:	e822                	sd	s0,16(sp)
    800045f4:	e426                	sd	s1,8(sp)
    800045f6:	e04a                	sd	s2,0(sp)
    800045f8:	1000                	addi	s0,sp,32
    800045fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fc:	00850913          	addi	s2,a0,8
    80004600:	854a                	mv	a0,s2
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000460a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000460e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004612:	8526                	mv	a0,s1
    80004614:	ffffe097          	auipc	ra,0xffffe
    80004618:	d8e080e7          	jalr	-626(ra) # 800023a2 <wakeup>
  release(&lk->lk);
    8000461c:	854a                	mv	a0,s2
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
}
    80004626:	60e2                	ld	ra,24(sp)
    80004628:	6442                	ld	s0,16(sp)
    8000462a:	64a2                	ld	s1,8(sp)
    8000462c:	6902                	ld	s2,0(sp)
    8000462e:	6105                	addi	sp,sp,32
    80004630:	8082                	ret

0000000080004632 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004632:	7179                	addi	sp,sp,-48
    80004634:	f406                	sd	ra,40(sp)
    80004636:	f022                	sd	s0,32(sp)
    80004638:	ec26                	sd	s1,24(sp)
    8000463a:	e84a                	sd	s2,16(sp)
    8000463c:	e44e                	sd	s3,8(sp)
    8000463e:	1800                	addi	s0,sp,48
    80004640:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	59c080e7          	jalr	1436(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004650:	409c                	lw	a5,0(s1)
    80004652:	ef99                	bnez	a5,80004670 <holdingsleep+0x3e>
    80004654:	4481                	li	s1,0
  release(&lk->lk);
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	640080e7          	jalr	1600(ra) # 80000c98 <release>
  return r;
}
    80004660:	8526                	mv	a0,s1
    80004662:	70a2                	ld	ra,40(sp)
    80004664:	7402                	ld	s0,32(sp)
    80004666:	64e2                	ld	s1,24(sp)
    80004668:	6942                	ld	s2,16(sp)
    8000466a:	69a2                	ld	s3,8(sp)
    8000466c:	6145                	addi	sp,sp,48
    8000466e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004670:	0284a983          	lw	s3,40(s1)
    80004674:	ffffd097          	auipc	ra,0xffffd
    80004678:	33c080e7          	jalr	828(ra) # 800019b0 <myproc>
    8000467c:	5904                	lw	s1,48(a0)
    8000467e:	413484b3          	sub	s1,s1,s3
    80004682:	0014b493          	seqz	s1,s1
    80004686:	bfc1                	j	80004656 <holdingsleep+0x24>

0000000080004688 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004688:	1141                	addi	sp,sp,-16
    8000468a:	e406                	sd	ra,8(sp)
    8000468c:	e022                	sd	s0,0(sp)
    8000468e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004690:	00004597          	auipc	a1,0x4
    80004694:	01858593          	addi	a1,a1,24 # 800086a8 <syscalls+0x248>
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	d2050513          	addi	a0,a0,-736 # 800213b8 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	4b4080e7          	jalr	1204(ra) # 80000b54 <initlock>
}
    800046a8:	60a2                	ld	ra,8(sp)
    800046aa:	6402                	ld	s0,0(sp)
    800046ac:	0141                	addi	sp,sp,16
    800046ae:	8082                	ret

00000000800046b0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046b0:	1101                	addi	sp,sp,-32
    800046b2:	ec06                	sd	ra,24(sp)
    800046b4:	e822                	sd	s0,16(sp)
    800046b6:	e426                	sd	s1,8(sp)
    800046b8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ba:	0001d517          	auipc	a0,0x1d
    800046be:	cfe50513          	addi	a0,a0,-770 # 800213b8 <ftable>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	522080e7          	jalr	1314(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ca:	0001d497          	auipc	s1,0x1d
    800046ce:	d0648493          	addi	s1,s1,-762 # 800213d0 <ftable+0x18>
    800046d2:	0001e717          	auipc	a4,0x1e
    800046d6:	c9e70713          	addi	a4,a4,-866 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800046da:	40dc                	lw	a5,4(s1)
    800046dc:	cf99                	beqz	a5,800046fa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046de:	02848493          	addi	s1,s1,40
    800046e2:	fee49ce3          	bne	s1,a4,800046da <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046e6:	0001d517          	auipc	a0,0x1d
    800046ea:	cd250513          	addi	a0,a0,-814 # 800213b8 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	5aa080e7          	jalr	1450(ra) # 80000c98 <release>
  return 0;
    800046f6:	4481                	li	s1,0
    800046f8:	a819                	j	8000470e <filealloc+0x5e>
      f->ref = 1;
    800046fa:	4785                	li	a5,1
    800046fc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046fe:	0001d517          	auipc	a0,0x1d
    80004702:	cba50513          	addi	a0,a0,-838 # 800213b8 <ftable>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	592080e7          	jalr	1426(ra) # 80000c98 <release>
}
    8000470e:	8526                	mv	a0,s1
    80004710:	60e2                	ld	ra,24(sp)
    80004712:	6442                	ld	s0,16(sp)
    80004714:	64a2                	ld	s1,8(sp)
    80004716:	6105                	addi	sp,sp,32
    80004718:	8082                	ret

000000008000471a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000471a:	1101                	addi	sp,sp,-32
    8000471c:	ec06                	sd	ra,24(sp)
    8000471e:	e822                	sd	s0,16(sp)
    80004720:	e426                	sd	s1,8(sp)
    80004722:	1000                	addi	s0,sp,32
    80004724:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	c9250513          	addi	a0,a0,-878 # 800213b8 <ftable>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004736:	40dc                	lw	a5,4(s1)
    80004738:	02f05263          	blez	a5,8000475c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000473c:	2785                	addiw	a5,a5,1
    8000473e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	c7850513          	addi	a0,a0,-904 # 800213b8 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	550080e7          	jalr	1360(ra) # 80000c98 <release>
  return f;
}
    80004750:	8526                	mv	a0,s1
    80004752:	60e2                	ld	ra,24(sp)
    80004754:	6442                	ld	s0,16(sp)
    80004756:	64a2                	ld	s1,8(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret
    panic("filedup");
    8000475c:	00004517          	auipc	a0,0x4
    80004760:	f5450513          	addi	a0,a0,-172 # 800086b0 <syscalls+0x250>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>

000000008000476c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000476c:	7139                	addi	sp,sp,-64
    8000476e:	fc06                	sd	ra,56(sp)
    80004770:	f822                	sd	s0,48(sp)
    80004772:	f426                	sd	s1,40(sp)
    80004774:	f04a                	sd	s2,32(sp)
    80004776:	ec4e                	sd	s3,24(sp)
    80004778:	e852                	sd	s4,16(sp)
    8000477a:	e456                	sd	s5,8(sp)
    8000477c:	0080                	addi	s0,sp,64
    8000477e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	c3850513          	addi	a0,a0,-968 # 800213b8 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	45c080e7          	jalr	1116(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004790:	40dc                	lw	a5,4(s1)
    80004792:	06f05163          	blez	a5,800047f4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004796:	37fd                	addiw	a5,a5,-1
    80004798:	0007871b          	sext.w	a4,a5
    8000479c:	c0dc                	sw	a5,4(s1)
    8000479e:	06e04363          	bgtz	a4,80004804 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047a2:	0004a903          	lw	s2,0(s1)
    800047a6:	0094ca83          	lbu	s5,9(s1)
    800047aa:	0104ba03          	ld	s4,16(s1)
    800047ae:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047b2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047b6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ba:	0001d517          	auipc	a0,0x1d
    800047be:	bfe50513          	addi	a0,a0,-1026 # 800213b8 <ftable>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4d6080e7          	jalr	1238(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047ca:	4785                	li	a5,1
    800047cc:	04f90d63          	beq	s2,a5,80004826 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047d0:	3979                	addiw	s2,s2,-2
    800047d2:	4785                	li	a5,1
    800047d4:	0527e063          	bltu	a5,s2,80004814 <fileclose+0xa8>
    begin_op();
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	ac8080e7          	jalr	-1336(ra) # 800042a0 <begin_op>
    iput(ff.ip);
    800047e0:	854e                	mv	a0,s3
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	2a6080e7          	jalr	678(ra) # 80003a88 <iput>
    end_op();
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	b36080e7          	jalr	-1226(ra) # 80004320 <end_op>
    800047f2:	a00d                	j	80004814 <fileclose+0xa8>
    panic("fileclose");
    800047f4:	00004517          	auipc	a0,0x4
    800047f8:	ec450513          	addi	a0,a0,-316 # 800086b8 <syscalls+0x258>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004804:	0001d517          	auipc	a0,0x1d
    80004808:	bb450513          	addi	a0,a0,-1100 # 800213b8 <ftable>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	48c080e7          	jalr	1164(ra) # 80000c98 <release>
  }
}
    80004814:	70e2                	ld	ra,56(sp)
    80004816:	7442                	ld	s0,48(sp)
    80004818:	74a2                	ld	s1,40(sp)
    8000481a:	7902                	ld	s2,32(sp)
    8000481c:	69e2                	ld	s3,24(sp)
    8000481e:	6a42                	ld	s4,16(sp)
    80004820:	6aa2                	ld	s5,8(sp)
    80004822:	6121                	addi	sp,sp,64
    80004824:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004826:	85d6                	mv	a1,s5
    80004828:	8552                	mv	a0,s4
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	34c080e7          	jalr	844(ra) # 80004b76 <pipeclose>
    80004832:	b7cd                	j	80004814 <fileclose+0xa8>

0000000080004834 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004834:	715d                	addi	sp,sp,-80
    80004836:	e486                	sd	ra,72(sp)
    80004838:	e0a2                	sd	s0,64(sp)
    8000483a:	fc26                	sd	s1,56(sp)
    8000483c:	f84a                	sd	s2,48(sp)
    8000483e:	f44e                	sd	s3,40(sp)
    80004840:	0880                	addi	s0,sp,80
    80004842:	84aa                	mv	s1,a0
    80004844:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004846:	ffffd097          	auipc	ra,0xffffd
    8000484a:	16a080e7          	jalr	362(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000484e:	409c                	lw	a5,0(s1)
    80004850:	37f9                	addiw	a5,a5,-2
    80004852:	4705                	li	a4,1
    80004854:	04f76763          	bltu	a4,a5,800048a2 <filestat+0x6e>
    80004858:	892a                	mv	s2,a0
    ilock(f->ip);
    8000485a:	6c88                	ld	a0,24(s1)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	072080e7          	jalr	114(ra) # 800038ce <ilock>
    stati(f->ip, &st);
    80004864:	fb840593          	addi	a1,s0,-72
    80004868:	6c88                	ld	a0,24(s1)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	2ee080e7          	jalr	750(ra) # 80003b58 <stati>
    iunlock(f->ip);
    80004872:	6c88                	ld	a0,24(s1)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	11c080e7          	jalr	284(ra) # 80003990 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000487c:	46e1                	li	a3,24
    8000487e:	fb840613          	addi	a2,s0,-72
    80004882:	85ce                	mv	a1,s3
    80004884:	05093503          	ld	a0,80(s2)
    80004888:	ffffd097          	auipc	ra,0xffffd
    8000488c:	dea080e7          	jalr	-534(ra) # 80001672 <copyout>
    80004890:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004894:	60a6                	ld	ra,72(sp)
    80004896:	6406                	ld	s0,64(sp)
    80004898:	74e2                	ld	s1,56(sp)
    8000489a:	7942                	ld	s2,48(sp)
    8000489c:	79a2                	ld	s3,40(sp)
    8000489e:	6161                	addi	sp,sp,80
    800048a0:	8082                	ret
  return -1;
    800048a2:	557d                	li	a0,-1
    800048a4:	bfc5                	j	80004894 <filestat+0x60>

00000000800048a6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048a6:	7179                	addi	sp,sp,-48
    800048a8:	f406                	sd	ra,40(sp)
    800048aa:	f022                	sd	s0,32(sp)
    800048ac:	ec26                	sd	s1,24(sp)
    800048ae:	e84a                	sd	s2,16(sp)
    800048b0:	e44e                	sd	s3,8(sp)
    800048b2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048b4:	00854783          	lbu	a5,8(a0)
    800048b8:	c3d5                	beqz	a5,8000495c <fileread+0xb6>
    800048ba:	84aa                	mv	s1,a0
    800048bc:	89ae                	mv	s3,a1
    800048be:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048c0:	411c                	lw	a5,0(a0)
    800048c2:	4705                	li	a4,1
    800048c4:	04e78963          	beq	a5,a4,80004916 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048c8:	470d                	li	a4,3
    800048ca:	04e78d63          	beq	a5,a4,80004924 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048ce:	4709                	li	a4,2
    800048d0:	06e79e63          	bne	a5,a4,8000494c <fileread+0xa6>
    ilock(f->ip);
    800048d4:	6d08                	ld	a0,24(a0)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	ff8080e7          	jalr	-8(ra) # 800038ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048de:	874a                	mv	a4,s2
    800048e0:	5094                	lw	a3,32(s1)
    800048e2:	864e                	mv	a2,s3
    800048e4:	4585                	li	a1,1
    800048e6:	6c88                	ld	a0,24(s1)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	29a080e7          	jalr	666(ra) # 80003b82 <readi>
    800048f0:	892a                	mv	s2,a0
    800048f2:	00a05563          	blez	a0,800048fc <fileread+0x56>
      f->off += r;
    800048f6:	509c                	lw	a5,32(s1)
    800048f8:	9fa9                	addw	a5,a5,a0
    800048fa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048fc:	6c88                	ld	a0,24(s1)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	092080e7          	jalr	146(ra) # 80003990 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004906:	854a                	mv	a0,s2
    80004908:	70a2                	ld	ra,40(sp)
    8000490a:	7402                	ld	s0,32(sp)
    8000490c:	64e2                	ld	s1,24(sp)
    8000490e:	6942                	ld	s2,16(sp)
    80004910:	69a2                	ld	s3,8(sp)
    80004912:	6145                	addi	sp,sp,48
    80004914:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004916:	6908                	ld	a0,16(a0)
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	3c8080e7          	jalr	968(ra) # 80004ce0 <piperead>
    80004920:	892a                	mv	s2,a0
    80004922:	b7d5                	j	80004906 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004924:	02451783          	lh	a5,36(a0)
    80004928:	03079693          	slli	a3,a5,0x30
    8000492c:	92c1                	srli	a3,a3,0x30
    8000492e:	4725                	li	a4,9
    80004930:	02d76863          	bltu	a4,a3,80004960 <fileread+0xba>
    80004934:	0792                	slli	a5,a5,0x4
    80004936:	0001d717          	auipc	a4,0x1d
    8000493a:	9e270713          	addi	a4,a4,-1566 # 80021318 <devsw>
    8000493e:	97ba                	add	a5,a5,a4
    80004940:	639c                	ld	a5,0(a5)
    80004942:	c38d                	beqz	a5,80004964 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004944:	4505                	li	a0,1
    80004946:	9782                	jalr	a5
    80004948:	892a                	mv	s2,a0
    8000494a:	bf75                	j	80004906 <fileread+0x60>
    panic("fileread");
    8000494c:	00004517          	auipc	a0,0x4
    80004950:	d7c50513          	addi	a0,a0,-644 # 800086c8 <syscalls+0x268>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>
    return -1;
    8000495c:	597d                	li	s2,-1
    8000495e:	b765                	j	80004906 <fileread+0x60>
      return -1;
    80004960:	597d                	li	s2,-1
    80004962:	b755                	j	80004906 <fileread+0x60>
    80004964:	597d                	li	s2,-1
    80004966:	b745                	j	80004906 <fileread+0x60>

0000000080004968 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004968:	715d                	addi	sp,sp,-80
    8000496a:	e486                	sd	ra,72(sp)
    8000496c:	e0a2                	sd	s0,64(sp)
    8000496e:	fc26                	sd	s1,56(sp)
    80004970:	f84a                	sd	s2,48(sp)
    80004972:	f44e                	sd	s3,40(sp)
    80004974:	f052                	sd	s4,32(sp)
    80004976:	ec56                	sd	s5,24(sp)
    80004978:	e85a                	sd	s6,16(sp)
    8000497a:	e45e                	sd	s7,8(sp)
    8000497c:	e062                	sd	s8,0(sp)
    8000497e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004980:	00954783          	lbu	a5,9(a0)
    80004984:	10078663          	beqz	a5,80004a90 <filewrite+0x128>
    80004988:	892a                	mv	s2,a0
    8000498a:	8aae                	mv	s5,a1
    8000498c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000498e:	411c                	lw	a5,0(a0)
    80004990:	4705                	li	a4,1
    80004992:	02e78263          	beq	a5,a4,800049b6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004996:	470d                	li	a4,3
    80004998:	02e78663          	beq	a5,a4,800049c4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000499c:	4709                	li	a4,2
    8000499e:	0ee79163          	bne	a5,a4,80004a80 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049a2:	0ac05d63          	blez	a2,80004a5c <filewrite+0xf4>
    int i = 0;
    800049a6:	4981                	li	s3,0
    800049a8:	6b05                	lui	s6,0x1
    800049aa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049ae:	6b85                	lui	s7,0x1
    800049b0:	c00b8b9b          	addiw	s7,s7,-1024
    800049b4:	a861                	j	80004a4c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049b6:	6908                	ld	a0,16(a0)
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	22e080e7          	jalr	558(ra) # 80004be6 <pipewrite>
    800049c0:	8a2a                	mv	s4,a0
    800049c2:	a045                	j	80004a62 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049c4:	02451783          	lh	a5,36(a0)
    800049c8:	03079693          	slli	a3,a5,0x30
    800049cc:	92c1                	srli	a3,a3,0x30
    800049ce:	4725                	li	a4,9
    800049d0:	0cd76263          	bltu	a4,a3,80004a94 <filewrite+0x12c>
    800049d4:	0792                	slli	a5,a5,0x4
    800049d6:	0001d717          	auipc	a4,0x1d
    800049da:	94270713          	addi	a4,a4,-1726 # 80021318 <devsw>
    800049de:	97ba                	add	a5,a5,a4
    800049e0:	679c                	ld	a5,8(a5)
    800049e2:	cbdd                	beqz	a5,80004a98 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049e4:	4505                	li	a0,1
    800049e6:	9782                	jalr	a5
    800049e8:	8a2a                	mv	s4,a0
    800049ea:	a8a5                	j	80004a62 <filewrite+0xfa>
    800049ec:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	8b0080e7          	jalr	-1872(ra) # 800042a0 <begin_op>
      ilock(f->ip);
    800049f8:	01893503          	ld	a0,24(s2)
    800049fc:	fffff097          	auipc	ra,0xfffff
    80004a00:	ed2080e7          	jalr	-302(ra) # 800038ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a04:	8762                	mv	a4,s8
    80004a06:	02092683          	lw	a3,32(s2)
    80004a0a:	01598633          	add	a2,s3,s5
    80004a0e:	4585                	li	a1,1
    80004a10:	01893503          	ld	a0,24(s2)
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	266080e7          	jalr	614(ra) # 80003c7a <writei>
    80004a1c:	84aa                	mv	s1,a0
    80004a1e:	00a05763          	blez	a0,80004a2c <filewrite+0xc4>
        f->off += r;
    80004a22:	02092783          	lw	a5,32(s2)
    80004a26:	9fa9                	addw	a5,a5,a0
    80004a28:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a2c:	01893503          	ld	a0,24(s2)
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	f60080e7          	jalr	-160(ra) # 80003990 <iunlock>
      end_op();
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	8e8080e7          	jalr	-1816(ra) # 80004320 <end_op>

      if(r != n1){
    80004a40:	009c1f63          	bne	s8,s1,80004a5e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a44:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a48:	0149db63          	bge	s3,s4,80004a5e <filewrite+0xf6>
      int n1 = n - i;
    80004a4c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a50:	84be                	mv	s1,a5
    80004a52:	2781                	sext.w	a5,a5
    80004a54:	f8fb5ce3          	bge	s6,a5,800049ec <filewrite+0x84>
    80004a58:	84de                	mv	s1,s7
    80004a5a:	bf49                	j	800049ec <filewrite+0x84>
    int i = 0;
    80004a5c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a5e:	013a1f63          	bne	s4,s3,80004a7c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a62:	8552                	mv	a0,s4
    80004a64:	60a6                	ld	ra,72(sp)
    80004a66:	6406                	ld	s0,64(sp)
    80004a68:	74e2                	ld	s1,56(sp)
    80004a6a:	7942                	ld	s2,48(sp)
    80004a6c:	79a2                	ld	s3,40(sp)
    80004a6e:	7a02                	ld	s4,32(sp)
    80004a70:	6ae2                	ld	s5,24(sp)
    80004a72:	6b42                	ld	s6,16(sp)
    80004a74:	6ba2                	ld	s7,8(sp)
    80004a76:	6c02                	ld	s8,0(sp)
    80004a78:	6161                	addi	sp,sp,80
    80004a7a:	8082                	ret
    ret = (i == n ? n : -1);
    80004a7c:	5a7d                	li	s4,-1
    80004a7e:	b7d5                	j	80004a62 <filewrite+0xfa>
    panic("filewrite");
    80004a80:	00004517          	auipc	a0,0x4
    80004a84:	c5850513          	addi	a0,a0,-936 # 800086d8 <syscalls+0x278>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>
    return -1;
    80004a90:	5a7d                	li	s4,-1
    80004a92:	bfc1                	j	80004a62 <filewrite+0xfa>
      return -1;
    80004a94:	5a7d                	li	s4,-1
    80004a96:	b7f1                	j	80004a62 <filewrite+0xfa>
    80004a98:	5a7d                	li	s4,-1
    80004a9a:	b7e1                	j	80004a62 <filewrite+0xfa>

0000000080004a9c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a9c:	7179                	addi	sp,sp,-48
    80004a9e:	f406                	sd	ra,40(sp)
    80004aa0:	f022                	sd	s0,32(sp)
    80004aa2:	ec26                	sd	s1,24(sp)
    80004aa4:	e84a                	sd	s2,16(sp)
    80004aa6:	e44e                	sd	s3,8(sp)
    80004aa8:	e052                	sd	s4,0(sp)
    80004aaa:	1800                	addi	s0,sp,48
    80004aac:	84aa                	mv	s1,a0
    80004aae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ab0:	0005b023          	sd	zero,0(a1)
    80004ab4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	bf8080e7          	jalr	-1032(ra) # 800046b0 <filealloc>
    80004ac0:	e088                	sd	a0,0(s1)
    80004ac2:	c551                	beqz	a0,80004b4e <pipealloc+0xb2>
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	bec080e7          	jalr	-1044(ra) # 800046b0 <filealloc>
    80004acc:	00aa3023          	sd	a0,0(s4)
    80004ad0:	c92d                	beqz	a0,80004b42 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	022080e7          	jalr	34(ra) # 80000af4 <kalloc>
    80004ada:	892a                	mv	s2,a0
    80004adc:	c125                	beqz	a0,80004b3c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ade:	4985                	li	s3,1
    80004ae0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ae4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ae8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004af0:	00004597          	auipc	a1,0x4
    80004af4:	bf858593          	addi	a1,a1,-1032 # 800086e8 <syscalls+0x288>
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	05c080e7          	jalr	92(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b00:	609c                	ld	a5,0(s1)
    80004b02:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b06:	609c                	ld	a5,0(s1)
    80004b08:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b0c:	609c                	ld	a5,0(s1)
    80004b0e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b12:	609c                	ld	a5,0(s1)
    80004b14:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b18:	000a3783          	ld	a5,0(s4)
    80004b1c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b20:	000a3783          	ld	a5,0(s4)
    80004b24:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b28:	000a3783          	ld	a5,0(s4)
    80004b2c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b30:	000a3783          	ld	a5,0(s4)
    80004b34:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b38:	4501                	li	a0,0
    80004b3a:	a025                	j	80004b62 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b3c:	6088                	ld	a0,0(s1)
    80004b3e:	e501                	bnez	a0,80004b46 <pipealloc+0xaa>
    80004b40:	a039                	j	80004b4e <pipealloc+0xb2>
    80004b42:	6088                	ld	a0,0(s1)
    80004b44:	c51d                	beqz	a0,80004b72 <pipealloc+0xd6>
    fileclose(*f0);
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	c26080e7          	jalr	-986(ra) # 8000476c <fileclose>
  if(*f1)
    80004b4e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b52:	557d                	li	a0,-1
  if(*f1)
    80004b54:	c799                	beqz	a5,80004b62 <pipealloc+0xc6>
    fileclose(*f1);
    80004b56:	853e                	mv	a0,a5
    80004b58:	00000097          	auipc	ra,0x0
    80004b5c:	c14080e7          	jalr	-1004(ra) # 8000476c <fileclose>
  return -1;
    80004b60:	557d                	li	a0,-1
}
    80004b62:	70a2                	ld	ra,40(sp)
    80004b64:	7402                	ld	s0,32(sp)
    80004b66:	64e2                	ld	s1,24(sp)
    80004b68:	6942                	ld	s2,16(sp)
    80004b6a:	69a2                	ld	s3,8(sp)
    80004b6c:	6a02                	ld	s4,0(sp)
    80004b6e:	6145                	addi	sp,sp,48
    80004b70:	8082                	ret
  return -1;
    80004b72:	557d                	li	a0,-1
    80004b74:	b7fd                	j	80004b62 <pipealloc+0xc6>

0000000080004b76 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b76:	1101                	addi	sp,sp,-32
    80004b78:	ec06                	sd	ra,24(sp)
    80004b7a:	e822                	sd	s0,16(sp)
    80004b7c:	e426                	sd	s1,8(sp)
    80004b7e:	e04a                	sd	s2,0(sp)
    80004b80:	1000                	addi	s0,sp,32
    80004b82:	84aa                	mv	s1,a0
    80004b84:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
  if(writable){
    80004b8e:	02090d63          	beqz	s2,80004bc8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b92:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b96:	21848513          	addi	a0,s1,536
    80004b9a:	ffffe097          	auipc	ra,0xffffe
    80004b9e:	808080e7          	jalr	-2040(ra) # 800023a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ba2:	2204b783          	ld	a5,544(s1)
    80004ba6:	eb95                	bnez	a5,80004bda <pipeclose+0x64>
    release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	e44080e7          	jalr	-444(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bbc:	60e2                	ld	ra,24(sp)
    80004bbe:	6442                	ld	s0,16(sp)
    80004bc0:	64a2                	ld	s1,8(sp)
    80004bc2:	6902                	ld	s2,0(sp)
    80004bc4:	6105                	addi	sp,sp,32
    80004bc6:	8082                	ret
    pi->readopen = 0;
    80004bc8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bcc:	21c48513          	addi	a0,s1,540
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	7d2080e7          	jalr	2002(ra) # 800023a2 <wakeup>
    80004bd8:	b7e9                	j	80004ba2 <pipeclose+0x2c>
    release(&pi->lock);
    80004bda:	8526                	mv	a0,s1
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	0bc080e7          	jalr	188(ra) # 80000c98 <release>
}
    80004be4:	bfe1                	j	80004bbc <pipeclose+0x46>

0000000080004be6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004be6:	7159                	addi	sp,sp,-112
    80004be8:	f486                	sd	ra,104(sp)
    80004bea:	f0a2                	sd	s0,96(sp)
    80004bec:	eca6                	sd	s1,88(sp)
    80004bee:	e8ca                	sd	s2,80(sp)
    80004bf0:	e4ce                	sd	s3,72(sp)
    80004bf2:	e0d2                	sd	s4,64(sp)
    80004bf4:	fc56                	sd	s5,56(sp)
    80004bf6:	f85a                	sd	s6,48(sp)
    80004bf8:	f45e                	sd	s7,40(sp)
    80004bfa:	f062                	sd	s8,32(sp)
    80004bfc:	ec66                	sd	s9,24(sp)
    80004bfe:	1880                	addi	s0,sp,112
    80004c00:	84aa                	mv	s1,a0
    80004c02:	8aae                	mv	s5,a1
    80004c04:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	daa080e7          	jalr	-598(ra) # 800019b0 <myproc>
    80004c0e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	fd2080e7          	jalr	-46(ra) # 80000be4 <acquire>
  while(i < n){
    80004c1a:	0d405163          	blez	s4,80004cdc <pipewrite+0xf6>
    80004c1e:	8ba6                	mv	s7,s1
  int i = 0;
    80004c20:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c22:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c24:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c28:	21c48c13          	addi	s8,s1,540
    80004c2c:	a08d                	j	80004c8e <pipewrite+0xa8>
      release(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	068080e7          	jalr	104(ra) # 80000c98 <release>
      return -1;
    80004c38:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	70a6                	ld	ra,104(sp)
    80004c3e:	7406                	ld	s0,96(sp)
    80004c40:	64e6                	ld	s1,88(sp)
    80004c42:	6946                	ld	s2,80(sp)
    80004c44:	69a6                	ld	s3,72(sp)
    80004c46:	6a06                	ld	s4,64(sp)
    80004c48:	7ae2                	ld	s5,56(sp)
    80004c4a:	7b42                	ld	s6,48(sp)
    80004c4c:	7ba2                	ld	s7,40(sp)
    80004c4e:	7c02                	ld	s8,32(sp)
    80004c50:	6ce2                	ld	s9,24(sp)
    80004c52:	6165                	addi	sp,sp,112
    80004c54:	8082                	ret
      wakeup(&pi->nread);
    80004c56:	8566                	mv	a0,s9
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	74a080e7          	jalr	1866(ra) # 800023a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c60:	85de                	mv	a1,s7
    80004c62:	8562                	mv	a0,s8
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	5a8080e7          	jalr	1448(ra) # 8000220c <sleep>
    80004c6c:	a839                	j	80004c8a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c6e:	21c4a783          	lw	a5,540(s1)
    80004c72:	0017871b          	addiw	a4,a5,1
    80004c76:	20e4ae23          	sw	a4,540(s1)
    80004c7a:	1ff7f793          	andi	a5,a5,511
    80004c7e:	97a6                	add	a5,a5,s1
    80004c80:	f9f44703          	lbu	a4,-97(s0)
    80004c84:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c88:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c8a:	03495d63          	bge	s2,s4,80004cc4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c8e:	2204a783          	lw	a5,544(s1)
    80004c92:	dfd1                	beqz	a5,80004c2e <pipewrite+0x48>
    80004c94:	0289a783          	lw	a5,40(s3)
    80004c98:	fbd9                	bnez	a5,80004c2e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c9a:	2184a783          	lw	a5,536(s1)
    80004c9e:	21c4a703          	lw	a4,540(s1)
    80004ca2:	2007879b          	addiw	a5,a5,512
    80004ca6:	faf708e3          	beq	a4,a5,80004c56 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004caa:	4685                	li	a3,1
    80004cac:	01590633          	add	a2,s2,s5
    80004cb0:	f9f40593          	addi	a1,s0,-97
    80004cb4:	0509b503          	ld	a0,80(s3)
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	a46080e7          	jalr	-1466(ra) # 800016fe <copyin>
    80004cc0:	fb6517e3          	bne	a0,s6,80004c6e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cc4:	21848513          	addi	a0,s1,536
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	6da080e7          	jalr	1754(ra) # 800023a2 <wakeup>
  release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fc6080e7          	jalr	-58(ra) # 80000c98 <release>
  return i;
    80004cda:	b785                	j	80004c3a <pipewrite+0x54>
  int i = 0;
    80004cdc:	4901                	li	s2,0
    80004cde:	b7dd                	j	80004cc4 <pipewrite+0xde>

0000000080004ce0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ce0:	715d                	addi	sp,sp,-80
    80004ce2:	e486                	sd	ra,72(sp)
    80004ce4:	e0a2                	sd	s0,64(sp)
    80004ce6:	fc26                	sd	s1,56(sp)
    80004ce8:	f84a                	sd	s2,48(sp)
    80004cea:	f44e                	sd	s3,40(sp)
    80004cec:	f052                	sd	s4,32(sp)
    80004cee:	ec56                	sd	s5,24(sp)
    80004cf0:	e85a                	sd	s6,16(sp)
    80004cf2:	0880                	addi	s0,sp,80
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	892e                	mv	s2,a1
    80004cf8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	cb6080e7          	jalr	-842(ra) # 800019b0 <myproc>
    80004d02:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d04:	8b26                	mv	s6,s1
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	edc080e7          	jalr	-292(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d10:	2184a703          	lw	a4,536(s1)
    80004d14:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d18:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1c:	02f71463          	bne	a4,a5,80004d44 <piperead+0x64>
    80004d20:	2244a783          	lw	a5,548(s1)
    80004d24:	c385                	beqz	a5,80004d44 <piperead+0x64>
    if(pr->killed){
    80004d26:	028a2783          	lw	a5,40(s4)
    80004d2a:	ebc1                	bnez	a5,80004dba <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2c:	85da                	mv	a1,s6
    80004d2e:	854e                	mv	a0,s3
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	4dc080e7          	jalr	1244(ra) # 8000220c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d38:	2184a703          	lw	a4,536(s1)
    80004d3c:	21c4a783          	lw	a5,540(s1)
    80004d40:	fef700e3          	beq	a4,a5,80004d20 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d44:	09505263          	blez	s5,80004dc8 <piperead+0xe8>
    80004d48:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d4c:	2184a783          	lw	a5,536(s1)
    80004d50:	21c4a703          	lw	a4,540(s1)
    80004d54:	02f70d63          	beq	a4,a5,80004d8e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d58:	0017871b          	addiw	a4,a5,1
    80004d5c:	20e4ac23          	sw	a4,536(s1)
    80004d60:	1ff7f793          	andi	a5,a5,511
    80004d64:	97a6                	add	a5,a5,s1
    80004d66:	0187c783          	lbu	a5,24(a5)
    80004d6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d6e:	4685                	li	a3,1
    80004d70:	fbf40613          	addi	a2,s0,-65
    80004d74:	85ca                	mv	a1,s2
    80004d76:	050a3503          	ld	a0,80(s4)
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	8f8080e7          	jalr	-1800(ra) # 80001672 <copyout>
    80004d82:	01650663          	beq	a0,s6,80004d8e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d86:	2985                	addiw	s3,s3,1
    80004d88:	0905                	addi	s2,s2,1
    80004d8a:	fd3a91e3          	bne	s5,s3,80004d4c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d8e:	21c48513          	addi	a0,s1,540
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	610080e7          	jalr	1552(ra) # 800023a2 <wakeup>
  release(&pi->lock);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	efc080e7          	jalr	-260(ra) # 80000c98 <release>
  return i;
}
    80004da4:	854e                	mv	a0,s3
    80004da6:	60a6                	ld	ra,72(sp)
    80004da8:	6406                	ld	s0,64(sp)
    80004daa:	74e2                	ld	s1,56(sp)
    80004dac:	7942                	ld	s2,48(sp)
    80004dae:	79a2                	ld	s3,40(sp)
    80004db0:	7a02                	ld	s4,32(sp)
    80004db2:	6ae2                	ld	s5,24(sp)
    80004db4:	6b42                	ld	s6,16(sp)
    80004db6:	6161                	addi	sp,sp,80
    80004db8:	8082                	ret
      release(&pi->lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	edc080e7          	jalr	-292(ra) # 80000c98 <release>
      return -1;
    80004dc4:	59fd                	li	s3,-1
    80004dc6:	bff9                	j	80004da4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc8:	4981                	li	s3,0
    80004dca:	b7d1                	j	80004d8e <piperead+0xae>

0000000080004dcc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dcc:	df010113          	addi	sp,sp,-528
    80004dd0:	20113423          	sd	ra,520(sp)
    80004dd4:	20813023          	sd	s0,512(sp)
    80004dd8:	ffa6                	sd	s1,504(sp)
    80004dda:	fbca                	sd	s2,496(sp)
    80004ddc:	f7ce                	sd	s3,488(sp)
    80004dde:	f3d2                	sd	s4,480(sp)
    80004de0:	efd6                	sd	s5,472(sp)
    80004de2:	ebda                	sd	s6,464(sp)
    80004de4:	e7de                	sd	s7,456(sp)
    80004de6:	e3e2                	sd	s8,448(sp)
    80004de8:	ff66                	sd	s9,440(sp)
    80004dea:	fb6a                	sd	s10,432(sp)
    80004dec:	f76e                	sd	s11,424(sp)
    80004dee:	0c00                	addi	s0,sp,528
    80004df0:	84aa                	mv	s1,a0
    80004df2:	dea43c23          	sd	a0,-520(s0)
    80004df6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	bb6080e7          	jalr	-1098(ra) # 800019b0 <myproc>
    80004e02:	892a                	mv	s2,a0

  begin_op();
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	49c080e7          	jalr	1180(ra) # 800042a0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	276080e7          	jalr	630(ra) # 80004084 <namei>
    80004e16:	c92d                	beqz	a0,80004e88 <exec+0xbc>
    80004e18:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	ab4080e7          	jalr	-1356(ra) # 800038ce <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e22:	04000713          	li	a4,64
    80004e26:	4681                	li	a3,0
    80004e28:	e5040613          	addi	a2,s0,-432
    80004e2c:	4581                	li	a1,0
    80004e2e:	8526                	mv	a0,s1
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	d52080e7          	jalr	-686(ra) # 80003b82 <readi>
    80004e38:	04000793          	li	a5,64
    80004e3c:	00f51a63          	bne	a0,a5,80004e50 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e40:	e5042703          	lw	a4,-432(s0)
    80004e44:	464c47b7          	lui	a5,0x464c4
    80004e48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e4c:	04f70463          	beq	a4,a5,80004e94 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e50:	8526                	mv	a0,s1
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	cde080e7          	jalr	-802(ra) # 80003b30 <iunlockput>
    end_op();
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	4c6080e7          	jalr	1222(ra) # 80004320 <end_op>
  }
  return -1;
    80004e62:	557d                	li	a0,-1
}
    80004e64:	20813083          	ld	ra,520(sp)
    80004e68:	20013403          	ld	s0,512(sp)
    80004e6c:	74fe                	ld	s1,504(sp)
    80004e6e:	795e                	ld	s2,496(sp)
    80004e70:	79be                	ld	s3,488(sp)
    80004e72:	7a1e                	ld	s4,480(sp)
    80004e74:	6afe                	ld	s5,472(sp)
    80004e76:	6b5e                	ld	s6,464(sp)
    80004e78:	6bbe                	ld	s7,456(sp)
    80004e7a:	6c1e                	ld	s8,448(sp)
    80004e7c:	7cfa                	ld	s9,440(sp)
    80004e7e:	7d5a                	ld	s10,432(sp)
    80004e80:	7dba                	ld	s11,424(sp)
    80004e82:	21010113          	addi	sp,sp,528
    80004e86:	8082                	ret
    end_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	498080e7          	jalr	1176(ra) # 80004320 <end_op>
    return -1;
    80004e90:	557d                	li	a0,-1
    80004e92:	bfc9                	j	80004e64 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e94:	854a                	mv	a0,s2
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	bde080e7          	jalr	-1058(ra) # 80001a74 <proc_pagetable>
    80004e9e:	8baa                	mv	s7,a0
    80004ea0:	d945                	beqz	a0,80004e50 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea2:	e7042983          	lw	s3,-400(s0)
    80004ea6:	e8845783          	lhu	a5,-376(s0)
    80004eaa:	c7ad                	beqz	a5,80004f14 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eae:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004eb0:	6c85                	lui	s9,0x1
    80004eb2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eb6:	def43823          	sd	a5,-528(s0)
    80004eba:	a42d                	j	800050e4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ebc:	00004517          	auipc	a0,0x4
    80004ec0:	83450513          	addi	a0,a0,-1996 # 800086f0 <syscalls+0x290>
    80004ec4:	ffffb097          	auipc	ra,0xffffb
    80004ec8:	67a080e7          	jalr	1658(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ecc:	8756                	mv	a4,s5
    80004ece:	012d86bb          	addw	a3,s11,s2
    80004ed2:	4581                	li	a1,0
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	cac080e7          	jalr	-852(ra) # 80003b82 <readi>
    80004ede:	2501                	sext.w	a0,a0
    80004ee0:	1aaa9963          	bne	s5,a0,80005092 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee4:	6785                	lui	a5,0x1
    80004ee6:	0127893b          	addw	s2,a5,s2
    80004eea:	77fd                	lui	a5,0xfffff
    80004eec:	01478a3b          	addw	s4,a5,s4
    80004ef0:	1f897163          	bgeu	s2,s8,800050d2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ef4:	02091593          	slli	a1,s2,0x20
    80004ef8:	9181                	srli	a1,a1,0x20
    80004efa:	95ea                	add	a1,a1,s10
    80004efc:	855e                	mv	a0,s7
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	170080e7          	jalr	368(ra) # 8000106e <walkaddr>
    80004f06:	862a                	mv	a2,a0
    if(pa == 0)
    80004f08:	d955                	beqz	a0,80004ebc <exec+0xf0>
      n = PGSIZE;
    80004f0a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f0c:	fd9a70e3          	bgeu	s4,s9,80004ecc <exec+0x100>
      n = sz - i;
    80004f10:	8ad2                	mv	s5,s4
    80004f12:	bf6d                	j	80004ecc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f14:	4901                	li	s2,0
  iunlockput(ip);
    80004f16:	8526                	mv	a0,s1
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	c18080e7          	jalr	-1000(ra) # 80003b30 <iunlockput>
  end_op();
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	400080e7          	jalr	1024(ra) # 80004320 <end_op>
  p = myproc();
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	a88080e7          	jalr	-1400(ra) # 800019b0 <myproc>
    80004f30:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f32:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f36:	6785                	lui	a5,0x1
    80004f38:	17fd                	addi	a5,a5,-1
    80004f3a:	993e                	add	s2,s2,a5
    80004f3c:	757d                	lui	a0,0xfffff
    80004f3e:	00a977b3          	and	a5,s2,a0
    80004f42:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f46:	6609                	lui	a2,0x2
    80004f48:	963e                	add	a2,a2,a5
    80004f4a:	85be                	mv	a1,a5
    80004f4c:	855e                	mv	a0,s7
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	4d4080e7          	jalr	1236(ra) # 80001422 <uvmalloc>
    80004f56:	8b2a                	mv	s6,a0
  ip = 0;
    80004f58:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f5a:	12050c63          	beqz	a0,80005092 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f5e:	75f9                	lui	a1,0xffffe
    80004f60:	95aa                	add	a1,a1,a0
    80004f62:	855e                	mv	a0,s7
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	6dc080e7          	jalr	1756(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f6c:	7c7d                	lui	s8,0xfffff
    80004f6e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f70:	e0043783          	ld	a5,-512(s0)
    80004f74:	6388                	ld	a0,0(a5)
    80004f76:	c535                	beqz	a0,80004fe2 <exec+0x216>
    80004f78:	e9040993          	addi	s3,s0,-368
    80004f7c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f80:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	ee2080e7          	jalr	-286(ra) # 80000e64 <strlen>
    80004f8a:	2505                	addiw	a0,a0,1
    80004f8c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f90:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f94:	13896363          	bltu	s2,s8,800050ba <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f98:	e0043d83          	ld	s11,-512(s0)
    80004f9c:	000dba03          	ld	s4,0(s11)
    80004fa0:	8552                	mv	a0,s4
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	ec2080e7          	jalr	-318(ra) # 80000e64 <strlen>
    80004faa:	0015069b          	addiw	a3,a0,1
    80004fae:	8652                	mv	a2,s4
    80004fb0:	85ca                	mv	a1,s2
    80004fb2:	855e                	mv	a0,s7
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	6be080e7          	jalr	1726(ra) # 80001672 <copyout>
    80004fbc:	10054363          	bltz	a0,800050c2 <exec+0x2f6>
    ustack[argc] = sp;
    80004fc0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc4:	0485                	addi	s1,s1,1
    80004fc6:	008d8793          	addi	a5,s11,8
    80004fca:	e0f43023          	sd	a5,-512(s0)
    80004fce:	008db503          	ld	a0,8(s11)
    80004fd2:	c911                	beqz	a0,80004fe6 <exec+0x21a>
    if(argc >= MAXARG)
    80004fd4:	09a1                	addi	s3,s3,8
    80004fd6:	fb3c96e3          	bne	s9,s3,80004f82 <exec+0x1b6>
  sz = sz1;
    80004fda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fde:	4481                	li	s1,0
    80004fe0:	a84d                	j	80005092 <exec+0x2c6>
  sp = sz;
    80004fe2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fe4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe6:	00349793          	slli	a5,s1,0x3
    80004fea:	f9040713          	addi	a4,s0,-112
    80004fee:	97ba                	add	a5,a5,a4
    80004ff0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ff4:	00148693          	addi	a3,s1,1
    80004ff8:	068e                	slli	a3,a3,0x3
    80004ffa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ffe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005002:	01897663          	bgeu	s2,s8,8000500e <exec+0x242>
  sz = sz1;
    80005006:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500a:	4481                	li	s1,0
    8000500c:	a059                	j	80005092 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000500e:	e9040613          	addi	a2,s0,-368
    80005012:	85ca                	mv	a1,s2
    80005014:	855e                	mv	a0,s7
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	65c080e7          	jalr	1628(ra) # 80001672 <copyout>
    8000501e:	0a054663          	bltz	a0,800050ca <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005022:	058ab783          	ld	a5,88(s5)
    80005026:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000502a:	df843783          	ld	a5,-520(s0)
    8000502e:	0007c703          	lbu	a4,0(a5)
    80005032:	cf11                	beqz	a4,8000504e <exec+0x282>
    80005034:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005036:	02f00693          	li	a3,47
    8000503a:	a039                	j	80005048 <exec+0x27c>
      last = s+1;
    8000503c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005040:	0785                	addi	a5,a5,1
    80005042:	fff7c703          	lbu	a4,-1(a5)
    80005046:	c701                	beqz	a4,8000504e <exec+0x282>
    if(*s == '/')
    80005048:	fed71ce3          	bne	a4,a3,80005040 <exec+0x274>
    8000504c:	bfc5                	j	8000503c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000504e:	4641                	li	a2,16
    80005050:	df843583          	ld	a1,-520(s0)
    80005054:	158a8513          	addi	a0,s5,344
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	dda080e7          	jalr	-550(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005060:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005064:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005068:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000506c:	058ab783          	ld	a5,88(s5)
    80005070:	e6843703          	ld	a4,-408(s0)
    80005074:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005076:	058ab783          	ld	a5,88(s5)
    8000507a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000507e:	85ea                	mv	a1,s10
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	a90080e7          	jalr	-1392(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005088:	0004851b          	sext.w	a0,s1
    8000508c:	bbe1                	j	80004e64 <exec+0x98>
    8000508e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005092:	e0843583          	ld	a1,-504(s0)
    80005096:	855e                	mv	a0,s7
    80005098:	ffffd097          	auipc	ra,0xffffd
    8000509c:	a78080e7          	jalr	-1416(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800050a0:	da0498e3          	bnez	s1,80004e50 <exec+0x84>
  return -1;
    800050a4:	557d                	li	a0,-1
    800050a6:	bb7d                	j	80004e64 <exec+0x98>
    800050a8:	e1243423          	sd	s2,-504(s0)
    800050ac:	b7dd                	j	80005092 <exec+0x2c6>
    800050ae:	e1243423          	sd	s2,-504(s0)
    800050b2:	b7c5                	j	80005092 <exec+0x2c6>
    800050b4:	e1243423          	sd	s2,-504(s0)
    800050b8:	bfe9                	j	80005092 <exec+0x2c6>
  sz = sz1;
    800050ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050be:	4481                	li	s1,0
    800050c0:	bfc9                	j	80005092 <exec+0x2c6>
  sz = sz1;
    800050c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c6:	4481                	li	s1,0
    800050c8:	b7e9                	j	80005092 <exec+0x2c6>
  sz = sz1;
    800050ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ce:	4481                	li	s1,0
    800050d0:	b7c9                	j	80005092 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050d2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d6:	2b05                	addiw	s6,s6,1
    800050d8:	0389899b          	addiw	s3,s3,56
    800050dc:	e8845783          	lhu	a5,-376(s0)
    800050e0:	e2fb5be3          	bge	s6,a5,80004f16 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e4:	2981                	sext.w	s3,s3
    800050e6:	03800713          	li	a4,56
    800050ea:	86ce                	mv	a3,s3
    800050ec:	e1840613          	addi	a2,s0,-488
    800050f0:	4581                	li	a1,0
    800050f2:	8526                	mv	a0,s1
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	a8e080e7          	jalr	-1394(ra) # 80003b82 <readi>
    800050fc:	03800793          	li	a5,56
    80005100:	f8f517e3          	bne	a0,a5,8000508e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005104:	e1842783          	lw	a5,-488(s0)
    80005108:	4705                	li	a4,1
    8000510a:	fce796e3          	bne	a5,a4,800050d6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000510e:	e4043603          	ld	a2,-448(s0)
    80005112:	e3843783          	ld	a5,-456(s0)
    80005116:	f8f669e3          	bltu	a2,a5,800050a8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000511a:	e2843783          	ld	a5,-472(s0)
    8000511e:	963e                	add	a2,a2,a5
    80005120:	f8f667e3          	bltu	a2,a5,800050ae <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005124:	85ca                	mv	a1,s2
    80005126:	855e                	mv	a0,s7
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	2fa080e7          	jalr	762(ra) # 80001422 <uvmalloc>
    80005130:	e0a43423          	sd	a0,-504(s0)
    80005134:	d141                	beqz	a0,800050b4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005136:	e2843d03          	ld	s10,-472(s0)
    8000513a:	df043783          	ld	a5,-528(s0)
    8000513e:	00fd77b3          	and	a5,s10,a5
    80005142:	fba1                	bnez	a5,80005092 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005144:	e2042d83          	lw	s11,-480(s0)
    80005148:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000514c:	f80c03e3          	beqz	s8,800050d2 <exec+0x306>
    80005150:	8a62                	mv	s4,s8
    80005152:	4901                	li	s2,0
    80005154:	b345                	j	80004ef4 <exec+0x128>

0000000080005156 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005156:	7179                	addi	sp,sp,-48
    80005158:	f406                	sd	ra,40(sp)
    8000515a:	f022                	sd	s0,32(sp)
    8000515c:	ec26                	sd	s1,24(sp)
    8000515e:	e84a                	sd	s2,16(sp)
    80005160:	1800                	addi	s0,sp,48
    80005162:	892e                	mv	s2,a1
    80005164:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005166:	fdc40593          	addi	a1,s0,-36
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	b56080e7          	jalr	-1194(ra) # 80002cc0 <argint>
    80005172:	04054063          	bltz	a0,800051b2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005176:	fdc42703          	lw	a4,-36(s0)
    8000517a:	47bd                	li	a5,15
    8000517c:	02e7ed63          	bltu	a5,a4,800051b6 <argfd+0x60>
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	830080e7          	jalr	-2000(ra) # 800019b0 <myproc>
    80005188:	fdc42703          	lw	a4,-36(s0)
    8000518c:	01a70793          	addi	a5,a4,26
    80005190:	078e                	slli	a5,a5,0x3
    80005192:	953e                	add	a0,a0,a5
    80005194:	611c                	ld	a5,0(a0)
    80005196:	c395                	beqz	a5,800051ba <argfd+0x64>
    return -1;
  if(pfd)
    80005198:	00090463          	beqz	s2,800051a0 <argfd+0x4a>
    *pfd = fd;
    8000519c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a0:	4501                	li	a0,0
  if(pf)
    800051a2:	c091                	beqz	s1,800051a6 <argfd+0x50>
    *pf = f;
    800051a4:	e09c                	sd	a5,0(s1)
}
    800051a6:	70a2                	ld	ra,40(sp)
    800051a8:	7402                	ld	s0,32(sp)
    800051aa:	64e2                	ld	s1,24(sp)
    800051ac:	6942                	ld	s2,16(sp)
    800051ae:	6145                	addi	sp,sp,48
    800051b0:	8082                	ret
    return -1;
    800051b2:	557d                	li	a0,-1
    800051b4:	bfcd                	j	800051a6 <argfd+0x50>
    return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	b7fd                	j	800051a6 <argfd+0x50>
    800051ba:	557d                	li	a0,-1
    800051bc:	b7ed                	j	800051a6 <argfd+0x50>

00000000800051be <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051be:	1101                	addi	sp,sp,-32
    800051c0:	ec06                	sd	ra,24(sp)
    800051c2:	e822                	sd	s0,16(sp)
    800051c4:	e426                	sd	s1,8(sp)
    800051c6:	1000                	addi	s0,sp,32
    800051c8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	7e6080e7          	jalr	2022(ra) # 800019b0 <myproc>
    800051d2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800051d8:	4501                	li	a0,0
    800051da:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051dc:	6398                	ld	a4,0(a5)
    800051de:	cb19                	beqz	a4,800051f4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e0:	2505                	addiw	a0,a0,1
    800051e2:	07a1                	addi	a5,a5,8
    800051e4:	fed51ce3          	bne	a0,a3,800051dc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051e8:	557d                	li	a0,-1
}
    800051ea:	60e2                	ld	ra,24(sp)
    800051ec:	6442                	ld	s0,16(sp)
    800051ee:	64a2                	ld	s1,8(sp)
    800051f0:	6105                	addi	sp,sp,32
    800051f2:	8082                	ret
      p->ofile[fd] = f;
    800051f4:	01a50793          	addi	a5,a0,26
    800051f8:	078e                	slli	a5,a5,0x3
    800051fa:	963e                	add	a2,a2,a5
    800051fc:	e204                	sd	s1,0(a2)
      return fd;
    800051fe:	b7f5                	j	800051ea <fdalloc+0x2c>

0000000080005200 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005200:	715d                	addi	sp,sp,-80
    80005202:	e486                	sd	ra,72(sp)
    80005204:	e0a2                	sd	s0,64(sp)
    80005206:	fc26                	sd	s1,56(sp)
    80005208:	f84a                	sd	s2,48(sp)
    8000520a:	f44e                	sd	s3,40(sp)
    8000520c:	f052                	sd	s4,32(sp)
    8000520e:	ec56                	sd	s5,24(sp)
    80005210:	0880                	addi	s0,sp,80
    80005212:	89ae                	mv	s3,a1
    80005214:	8ab2                	mv	s5,a2
    80005216:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005218:	fb040593          	addi	a1,s0,-80
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	e86080e7          	jalr	-378(ra) # 800040a2 <nameiparent>
    80005224:	892a                	mv	s2,a0
    80005226:	12050f63          	beqz	a0,80005364 <create+0x164>
    return 0;

  ilock(dp);
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	6a4080e7          	jalr	1700(ra) # 800038ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005232:	4601                	li	a2,0
    80005234:	fb040593          	addi	a1,s0,-80
    80005238:	854a                	mv	a0,s2
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	b78080e7          	jalr	-1160(ra) # 80003db2 <dirlookup>
    80005242:	84aa                	mv	s1,a0
    80005244:	c921                	beqz	a0,80005294 <create+0x94>
    iunlockput(dp);
    80005246:	854a                	mv	a0,s2
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	8e8080e7          	jalr	-1816(ra) # 80003b30 <iunlockput>
    ilock(ip);
    80005250:	8526                	mv	a0,s1
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	67c080e7          	jalr	1660(ra) # 800038ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000525a:	2981                	sext.w	s3,s3
    8000525c:	4789                	li	a5,2
    8000525e:	02f99463          	bne	s3,a5,80005286 <create+0x86>
    80005262:	0444d783          	lhu	a5,68(s1)
    80005266:	37f9                	addiw	a5,a5,-2
    80005268:	17c2                	slli	a5,a5,0x30
    8000526a:	93c1                	srli	a5,a5,0x30
    8000526c:	4705                	li	a4,1
    8000526e:	00f76c63          	bltu	a4,a5,80005286 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005272:	8526                	mv	a0,s1
    80005274:	60a6                	ld	ra,72(sp)
    80005276:	6406                	ld	s0,64(sp)
    80005278:	74e2                	ld	s1,56(sp)
    8000527a:	7942                	ld	s2,48(sp)
    8000527c:	79a2                	ld	s3,40(sp)
    8000527e:	7a02                	ld	s4,32(sp)
    80005280:	6ae2                	ld	s5,24(sp)
    80005282:	6161                	addi	sp,sp,80
    80005284:	8082                	ret
    iunlockput(ip);
    80005286:	8526                	mv	a0,s1
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	8a8080e7          	jalr	-1880(ra) # 80003b30 <iunlockput>
    return 0;
    80005290:	4481                	li	s1,0
    80005292:	b7c5                	j	80005272 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005294:	85ce                	mv	a1,s3
    80005296:	00092503          	lw	a0,0(s2)
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	49c080e7          	jalr	1180(ra) # 80003736 <ialloc>
    800052a2:	84aa                	mv	s1,a0
    800052a4:	c529                	beqz	a0,800052ee <create+0xee>
  ilock(ip);
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	628080e7          	jalr	1576(ra) # 800038ce <ilock>
  ip->major = major;
    800052ae:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052b6:	4785                	li	a5,1
    800052b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052bc:	8526                	mv	a0,s1
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	546080e7          	jalr	1350(ra) # 80003804 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052c6:	2981                	sext.w	s3,s3
    800052c8:	4785                	li	a5,1
    800052ca:	02f98a63          	beq	s3,a5,800052fe <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ce:	40d0                	lw	a2,4(s1)
    800052d0:	fb040593          	addi	a1,s0,-80
    800052d4:	854a                	mv	a0,s2
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	cec080e7          	jalr	-788(ra) # 80003fc2 <dirlink>
    800052de:	06054b63          	bltz	a0,80005354 <create+0x154>
  iunlockput(dp);
    800052e2:	854a                	mv	a0,s2
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	84c080e7          	jalr	-1972(ra) # 80003b30 <iunlockput>
  return ip;
    800052ec:	b759                	j	80005272 <create+0x72>
    panic("create: ialloc");
    800052ee:	00003517          	auipc	a0,0x3
    800052f2:	42250513          	addi	a0,a0,1058 # 80008710 <syscalls+0x2b0>
    800052f6:	ffffb097          	auipc	ra,0xffffb
    800052fa:	248080e7          	jalr	584(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052fe:	04a95783          	lhu	a5,74(s2)
    80005302:	2785                	addiw	a5,a5,1
    80005304:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005308:	854a                	mv	a0,s2
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	4fa080e7          	jalr	1274(ra) # 80003804 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005312:	40d0                	lw	a2,4(s1)
    80005314:	00003597          	auipc	a1,0x3
    80005318:	40c58593          	addi	a1,a1,1036 # 80008720 <syscalls+0x2c0>
    8000531c:	8526                	mv	a0,s1
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	ca4080e7          	jalr	-860(ra) # 80003fc2 <dirlink>
    80005326:	00054f63          	bltz	a0,80005344 <create+0x144>
    8000532a:	00492603          	lw	a2,4(s2)
    8000532e:	00003597          	auipc	a1,0x3
    80005332:	3fa58593          	addi	a1,a1,1018 # 80008728 <syscalls+0x2c8>
    80005336:	8526                	mv	a0,s1
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	c8a080e7          	jalr	-886(ra) # 80003fc2 <dirlink>
    80005340:	f80557e3          	bgez	a0,800052ce <create+0xce>
      panic("create dots");
    80005344:	00003517          	auipc	a0,0x3
    80005348:	3ec50513          	addi	a0,a0,1004 # 80008730 <syscalls+0x2d0>
    8000534c:	ffffb097          	auipc	ra,0xffffb
    80005350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005354:	00003517          	auipc	a0,0x3
    80005358:	3ec50513          	addi	a0,a0,1004 # 80008740 <syscalls+0x2e0>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
    return 0;
    80005364:	84aa                	mv	s1,a0
    80005366:	b731                	j	80005272 <create+0x72>

0000000080005368 <sys_dup>:
{
    80005368:	7179                	addi	sp,sp,-48
    8000536a:	f406                	sd	ra,40(sp)
    8000536c:	f022                	sd	s0,32(sp)
    8000536e:	ec26                	sd	s1,24(sp)
    80005370:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005372:	fd840613          	addi	a2,s0,-40
    80005376:	4581                	li	a1,0
    80005378:	4501                	li	a0,0
    8000537a:	00000097          	auipc	ra,0x0
    8000537e:	ddc080e7          	jalr	-548(ra) # 80005156 <argfd>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005384:	02054363          	bltz	a0,800053aa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005388:	fd843503          	ld	a0,-40(s0)
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	e32080e7          	jalr	-462(ra) # 800051be <fdalloc>
    80005394:	84aa                	mv	s1,a0
    return -1;
    80005396:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005398:	00054963          	bltz	a0,800053aa <sys_dup+0x42>
  filedup(f);
    8000539c:	fd843503          	ld	a0,-40(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	37a080e7          	jalr	890(ra) # 8000471a <filedup>
  return fd;
    800053a8:	87a6                	mv	a5,s1
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	70a2                	ld	ra,40(sp)
    800053ae:	7402                	ld	s0,32(sp)
    800053b0:	64e2                	ld	s1,24(sp)
    800053b2:	6145                	addi	sp,sp,48
    800053b4:	8082                	ret

00000000800053b6 <sys_read>:
{
    800053b6:	7179                	addi	sp,sp,-48
    800053b8:	f406                	sd	ra,40(sp)
    800053ba:	f022                	sd	s0,32(sp)
    800053bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	fe840613          	addi	a2,s0,-24
    800053c2:	4581                	li	a1,0
    800053c4:	4501                	li	a0,0
    800053c6:	00000097          	auipc	ra,0x0
    800053ca:	d90080e7          	jalr	-624(ra) # 80005156 <argfd>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	04054163          	bltz	a0,80005412 <sys_read+0x5c>
    800053d4:	fe440593          	addi	a1,s0,-28
    800053d8:	4509                	li	a0,2
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	8e6080e7          	jalr	-1818(ra) # 80002cc0 <argint>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e4:	02054763          	bltz	a0,80005412 <sys_read+0x5c>
    800053e8:	fd840593          	addi	a1,s0,-40
    800053ec:	4505                	li	a0,1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	8f4080e7          	jalr	-1804(ra) # 80002ce2 <argaddr>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f8:	00054d63          	bltz	a0,80005412 <sys_read+0x5c>
  return fileread(f, p, n);
    800053fc:	fe442603          	lw	a2,-28(s0)
    80005400:	fd843583          	ld	a1,-40(s0)
    80005404:	fe843503          	ld	a0,-24(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	49e080e7          	jalr	1182(ra) # 800048a6 <fileread>
    80005410:	87aa                	mv	a5,a0
}
    80005412:	853e                	mv	a0,a5
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	6145                	addi	sp,sp,48
    8000541a:	8082                	ret

000000008000541c <sys_write>:
{
    8000541c:	7179                	addi	sp,sp,-48
    8000541e:	f406                	sd	ra,40(sp)
    80005420:	f022                	sd	s0,32(sp)
    80005422:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005424:	fe840613          	addi	a2,s0,-24
    80005428:	4581                	li	a1,0
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	d2a080e7          	jalr	-726(ra) # 80005156 <argfd>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005436:	04054163          	bltz	a0,80005478 <sys_write+0x5c>
    8000543a:	fe440593          	addi	a1,s0,-28
    8000543e:	4509                	li	a0,2
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	880080e7          	jalr	-1920(ra) # 80002cc0 <argint>
    return -1;
    80005448:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544a:	02054763          	bltz	a0,80005478 <sys_write+0x5c>
    8000544e:	fd840593          	addi	a1,s0,-40
    80005452:	4505                	li	a0,1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	88e080e7          	jalr	-1906(ra) # 80002ce2 <argaddr>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545e:	00054d63          	bltz	a0,80005478 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005462:	fe442603          	lw	a2,-28(s0)
    80005466:	fd843583          	ld	a1,-40(s0)
    8000546a:	fe843503          	ld	a0,-24(s0)
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	4fa080e7          	jalr	1274(ra) # 80004968 <filewrite>
    80005476:	87aa                	mv	a5,a0
}
    80005478:	853e                	mv	a0,a5
    8000547a:	70a2                	ld	ra,40(sp)
    8000547c:	7402                	ld	s0,32(sp)
    8000547e:	6145                	addi	sp,sp,48
    80005480:	8082                	ret

0000000080005482 <sys_close>:
{
    80005482:	1101                	addi	sp,sp,-32
    80005484:	ec06                	sd	ra,24(sp)
    80005486:	e822                	sd	s0,16(sp)
    80005488:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548a:	fe040613          	addi	a2,s0,-32
    8000548e:	fec40593          	addi	a1,s0,-20
    80005492:	4501                	li	a0,0
    80005494:	00000097          	auipc	ra,0x0
    80005498:	cc2080e7          	jalr	-830(ra) # 80005156 <argfd>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000549e:	02054463          	bltz	a0,800054c6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	50e080e7          	jalr	1294(ra) # 800019b0 <myproc>
    800054aa:	fec42783          	lw	a5,-20(s0)
    800054ae:	07e9                	addi	a5,a5,26
    800054b0:	078e                	slli	a5,a5,0x3
    800054b2:	97aa                	add	a5,a5,a0
    800054b4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054b8:	fe043503          	ld	a0,-32(s0)
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	2b0080e7          	jalr	688(ra) # 8000476c <fileclose>
  return 0;
    800054c4:	4781                	li	a5,0
}
    800054c6:	853e                	mv	a0,a5
    800054c8:	60e2                	ld	ra,24(sp)
    800054ca:	6442                	ld	s0,16(sp)
    800054cc:	6105                	addi	sp,sp,32
    800054ce:	8082                	ret

00000000800054d0 <sys_fstat>:
{
    800054d0:	1101                	addi	sp,sp,-32
    800054d2:	ec06                	sd	ra,24(sp)
    800054d4:	e822                	sd	s0,16(sp)
    800054d6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054d8:	fe840613          	addi	a2,s0,-24
    800054dc:	4581                	li	a1,0
    800054de:	4501                	li	a0,0
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	c76080e7          	jalr	-906(ra) # 80005156 <argfd>
    return -1;
    800054e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ea:	02054563          	bltz	a0,80005514 <sys_fstat+0x44>
    800054ee:	fe040593          	addi	a1,s0,-32
    800054f2:	4505                	li	a0,1
    800054f4:	ffffd097          	auipc	ra,0xffffd
    800054f8:	7ee080e7          	jalr	2030(ra) # 80002ce2 <argaddr>
    return -1;
    800054fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fe:	00054b63          	bltz	a0,80005514 <sys_fstat+0x44>
  return filestat(f, st);
    80005502:	fe043583          	ld	a1,-32(s0)
    80005506:	fe843503          	ld	a0,-24(s0)
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	32a080e7          	jalr	810(ra) # 80004834 <filestat>
    80005512:	87aa                	mv	a5,a0
}
    80005514:	853e                	mv	a0,a5
    80005516:	60e2                	ld	ra,24(sp)
    80005518:	6442                	ld	s0,16(sp)
    8000551a:	6105                	addi	sp,sp,32
    8000551c:	8082                	ret

000000008000551e <sys_link>:
{
    8000551e:	7169                	addi	sp,sp,-304
    80005520:	f606                	sd	ra,296(sp)
    80005522:	f222                	sd	s0,288(sp)
    80005524:	ee26                	sd	s1,280(sp)
    80005526:	ea4a                	sd	s2,272(sp)
    80005528:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552a:	08000613          	li	a2,128
    8000552e:	ed040593          	addi	a1,s0,-304
    80005532:	4501                	li	a0,0
    80005534:	ffffd097          	auipc	ra,0xffffd
    80005538:	7d0080e7          	jalr	2000(ra) # 80002d04 <argstr>
    return -1;
    8000553c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553e:	10054e63          	bltz	a0,8000565a <sys_link+0x13c>
    80005542:	08000613          	li	a2,128
    80005546:	f5040593          	addi	a1,s0,-176
    8000554a:	4505                	li	a0,1
    8000554c:	ffffd097          	auipc	ra,0xffffd
    80005550:	7b8080e7          	jalr	1976(ra) # 80002d04 <argstr>
    return -1;
    80005554:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005556:	10054263          	bltz	a0,8000565a <sys_link+0x13c>
  begin_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	d46080e7          	jalr	-698(ra) # 800042a0 <begin_op>
  if((ip = namei(old)) == 0){
    80005562:	ed040513          	addi	a0,s0,-304
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	b1e080e7          	jalr	-1250(ra) # 80004084 <namei>
    8000556e:	84aa                	mv	s1,a0
    80005570:	c551                	beqz	a0,800055fc <sys_link+0xde>
  ilock(ip);
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	35c080e7          	jalr	860(ra) # 800038ce <ilock>
  if(ip->type == T_DIR){
    8000557a:	04449703          	lh	a4,68(s1)
    8000557e:	4785                	li	a5,1
    80005580:	08f70463          	beq	a4,a5,80005608 <sys_link+0xea>
  ip->nlink++;
    80005584:	04a4d783          	lhu	a5,74(s1)
    80005588:	2785                	addiw	a5,a5,1
    8000558a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	274080e7          	jalr	628(ra) # 80003804 <iupdate>
  iunlock(ip);
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	3f6080e7          	jalr	1014(ra) # 80003990 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a2:	fd040593          	addi	a1,s0,-48
    800055a6:	f5040513          	addi	a0,s0,-176
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	af8080e7          	jalr	-1288(ra) # 800040a2 <nameiparent>
    800055b2:	892a                	mv	s2,a0
    800055b4:	c935                	beqz	a0,80005628 <sys_link+0x10a>
  ilock(dp);
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	318080e7          	jalr	792(ra) # 800038ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055be:	00092703          	lw	a4,0(s2)
    800055c2:	409c                	lw	a5,0(s1)
    800055c4:	04f71d63          	bne	a4,a5,8000561e <sys_link+0x100>
    800055c8:	40d0                	lw	a2,4(s1)
    800055ca:	fd040593          	addi	a1,s0,-48
    800055ce:	854a                	mv	a0,s2
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	9f2080e7          	jalr	-1550(ra) # 80003fc2 <dirlink>
    800055d8:	04054363          	bltz	a0,8000561e <sys_link+0x100>
  iunlockput(dp);
    800055dc:	854a                	mv	a0,s2
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	552080e7          	jalr	1362(ra) # 80003b30 <iunlockput>
  iput(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	4a0080e7          	jalr	1184(ra) # 80003a88 <iput>
  end_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	d30080e7          	jalr	-720(ra) # 80004320 <end_op>
  return 0;
    800055f8:	4781                	li	a5,0
    800055fa:	a085                	j	8000565a <sys_link+0x13c>
    end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	d24080e7          	jalr	-732(ra) # 80004320 <end_op>
    return -1;
    80005604:	57fd                	li	a5,-1
    80005606:	a891                	j	8000565a <sys_link+0x13c>
    iunlockput(ip);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	526080e7          	jalr	1318(ra) # 80003b30 <iunlockput>
    end_op();
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	d0e080e7          	jalr	-754(ra) # 80004320 <end_op>
    return -1;
    8000561a:	57fd                	li	a5,-1
    8000561c:	a83d                	j	8000565a <sys_link+0x13c>
    iunlockput(dp);
    8000561e:	854a                	mv	a0,s2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	510080e7          	jalr	1296(ra) # 80003b30 <iunlockput>
  ilock(ip);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	2a4080e7          	jalr	676(ra) # 800038ce <ilock>
  ip->nlink--;
    80005632:	04a4d783          	lhu	a5,74(s1)
    80005636:	37fd                	addiw	a5,a5,-1
    80005638:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	1c6080e7          	jalr	454(ra) # 80003804 <iupdate>
  iunlockput(ip);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	4e8080e7          	jalr	1256(ra) # 80003b30 <iunlockput>
  end_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	cd0080e7          	jalr	-816(ra) # 80004320 <end_op>
  return -1;
    80005658:	57fd                	li	a5,-1
}
    8000565a:	853e                	mv	a0,a5
    8000565c:	70b2                	ld	ra,296(sp)
    8000565e:	7412                	ld	s0,288(sp)
    80005660:	64f2                	ld	s1,280(sp)
    80005662:	6952                	ld	s2,272(sp)
    80005664:	6155                	addi	sp,sp,304
    80005666:	8082                	ret

0000000080005668 <sys_unlink>:
{
    80005668:	7151                	addi	sp,sp,-240
    8000566a:	f586                	sd	ra,232(sp)
    8000566c:	f1a2                	sd	s0,224(sp)
    8000566e:	eda6                	sd	s1,216(sp)
    80005670:	e9ca                	sd	s2,208(sp)
    80005672:	e5ce                	sd	s3,200(sp)
    80005674:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005676:	08000613          	li	a2,128
    8000567a:	f3040593          	addi	a1,s0,-208
    8000567e:	4501                	li	a0,0
    80005680:	ffffd097          	auipc	ra,0xffffd
    80005684:	684080e7          	jalr	1668(ra) # 80002d04 <argstr>
    80005688:	18054163          	bltz	a0,8000580a <sys_unlink+0x1a2>
  begin_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	c14080e7          	jalr	-1004(ra) # 800042a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	f3040513          	addi	a0,s0,-208
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	a06080e7          	jalr	-1530(ra) # 800040a2 <nameiparent>
    800056a4:	84aa                	mv	s1,a0
    800056a6:	c979                	beqz	a0,8000577c <sys_unlink+0x114>
  ilock(dp);
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	226080e7          	jalr	550(ra) # 800038ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b0:	00003597          	auipc	a1,0x3
    800056b4:	07058593          	addi	a1,a1,112 # 80008720 <syscalls+0x2c0>
    800056b8:	fb040513          	addi	a0,s0,-80
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	6dc080e7          	jalr	1756(ra) # 80003d98 <namecmp>
    800056c4:	14050a63          	beqz	a0,80005818 <sys_unlink+0x1b0>
    800056c8:	00003597          	auipc	a1,0x3
    800056cc:	06058593          	addi	a1,a1,96 # 80008728 <syscalls+0x2c8>
    800056d0:	fb040513          	addi	a0,s0,-80
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	6c4080e7          	jalr	1732(ra) # 80003d98 <namecmp>
    800056dc:	12050e63          	beqz	a0,80005818 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e0:	f2c40613          	addi	a2,s0,-212
    800056e4:	fb040593          	addi	a1,s0,-80
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	6c8080e7          	jalr	1736(ra) # 80003db2 <dirlookup>
    800056f2:	892a                	mv	s2,a0
    800056f4:	12050263          	beqz	a0,80005818 <sys_unlink+0x1b0>
  ilock(ip);
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	1d6080e7          	jalr	470(ra) # 800038ce <ilock>
  if(ip->nlink < 1)
    80005700:	04a91783          	lh	a5,74(s2)
    80005704:	08f05263          	blez	a5,80005788 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005708:	04491703          	lh	a4,68(s2)
    8000570c:	4785                	li	a5,1
    8000570e:	08f70563          	beq	a4,a5,80005798 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005712:	4641                	li	a2,16
    80005714:	4581                	li	a1,0
    80005716:	fc040513          	addi	a0,s0,-64
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	5c6080e7          	jalr	1478(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005722:	4741                	li	a4,16
    80005724:	f2c42683          	lw	a3,-212(s0)
    80005728:	fc040613          	addi	a2,s0,-64
    8000572c:	4581                	li	a1,0
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	54a080e7          	jalr	1354(ra) # 80003c7a <writei>
    80005738:	47c1                	li	a5,16
    8000573a:	0af51563          	bne	a0,a5,800057e4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000573e:	04491703          	lh	a4,68(s2)
    80005742:	4785                	li	a5,1
    80005744:	0af70863          	beq	a4,a5,800057f4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	3e6080e7          	jalr	998(ra) # 80003b30 <iunlockput>
  ip->nlink--;
    80005752:	04a95783          	lhu	a5,74(s2)
    80005756:	37fd                	addiw	a5,a5,-1
    80005758:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000575c:	854a                	mv	a0,s2
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	0a6080e7          	jalr	166(ra) # 80003804 <iupdate>
  iunlockput(ip);
    80005766:	854a                	mv	a0,s2
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	3c8080e7          	jalr	968(ra) # 80003b30 <iunlockput>
  end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	bb0080e7          	jalr	-1104(ra) # 80004320 <end_op>
  return 0;
    80005778:	4501                	li	a0,0
    8000577a:	a84d                	j	8000582c <sys_unlink+0x1c4>
    end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	ba4080e7          	jalr	-1116(ra) # 80004320 <end_op>
    return -1;
    80005784:	557d                	li	a0,-1
    80005786:	a05d                	j	8000582c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005788:	00003517          	auipc	a0,0x3
    8000578c:	fc850513          	addi	a0,a0,-56 # 80008750 <syscalls+0x2f0>
    80005790:	ffffb097          	auipc	ra,0xffffb
    80005794:	dae080e7          	jalr	-594(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005798:	04c92703          	lw	a4,76(s2)
    8000579c:	02000793          	li	a5,32
    800057a0:	f6e7f9e3          	bgeu	a5,a4,80005712 <sys_unlink+0xaa>
    800057a4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057a8:	4741                	li	a4,16
    800057aa:	86ce                	mv	a3,s3
    800057ac:	f1840613          	addi	a2,s0,-232
    800057b0:	4581                	li	a1,0
    800057b2:	854a                	mv	a0,s2
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	3ce080e7          	jalr	974(ra) # 80003b82 <readi>
    800057bc:	47c1                	li	a5,16
    800057be:	00f51b63          	bne	a0,a5,800057d4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c2:	f1845783          	lhu	a5,-232(s0)
    800057c6:	e7a1                	bnez	a5,8000580e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057c8:	29c1                	addiw	s3,s3,16
    800057ca:	04c92783          	lw	a5,76(s2)
    800057ce:	fcf9ede3          	bltu	s3,a5,800057a8 <sys_unlink+0x140>
    800057d2:	b781                	j	80005712 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d4:	00003517          	auipc	a0,0x3
    800057d8:	f9450513          	addi	a0,a0,-108 # 80008768 <syscalls+0x308>
    800057dc:	ffffb097          	auipc	ra,0xffffb
    800057e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057e4:	00003517          	auipc	a0,0x3
    800057e8:	f9c50513          	addi	a0,a0,-100 # 80008780 <syscalls+0x320>
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>
    dp->nlink--;
    800057f4:	04a4d783          	lhu	a5,74(s1)
    800057f8:	37fd                	addiw	a5,a5,-1
    800057fa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	004080e7          	jalr	4(ra) # 80003804 <iupdate>
    80005808:	b781                	j	80005748 <sys_unlink+0xe0>
    return -1;
    8000580a:	557d                	li	a0,-1
    8000580c:	a005                	j	8000582c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	320080e7          	jalr	800(ra) # 80003b30 <iunlockput>
  iunlockput(dp);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	316080e7          	jalr	790(ra) # 80003b30 <iunlockput>
  end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	afe080e7          	jalr	-1282(ra) # 80004320 <end_op>
  return -1;
    8000582a:	557d                	li	a0,-1
}
    8000582c:	70ae                	ld	ra,232(sp)
    8000582e:	740e                	ld	s0,224(sp)
    80005830:	64ee                	ld	s1,216(sp)
    80005832:	694e                	ld	s2,208(sp)
    80005834:	69ae                	ld	s3,200(sp)
    80005836:	616d                	addi	sp,sp,240
    80005838:	8082                	ret

000000008000583a <sys_open>:

uint64
sys_open(void)
{
    8000583a:	7131                	addi	sp,sp,-192
    8000583c:	fd06                	sd	ra,184(sp)
    8000583e:	f922                	sd	s0,176(sp)
    80005840:	f526                	sd	s1,168(sp)
    80005842:	f14a                	sd	s2,160(sp)
    80005844:	ed4e                	sd	s3,152(sp)
    80005846:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005848:	08000613          	li	a2,128
    8000584c:	f5040593          	addi	a1,s0,-176
    80005850:	4501                	li	a0,0
    80005852:	ffffd097          	auipc	ra,0xffffd
    80005856:	4b2080e7          	jalr	1202(ra) # 80002d04 <argstr>
    return -1;
    8000585a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585c:	0c054163          	bltz	a0,8000591e <sys_open+0xe4>
    80005860:	f4c40593          	addi	a1,s0,-180
    80005864:	4505                	li	a0,1
    80005866:	ffffd097          	auipc	ra,0xffffd
    8000586a:	45a080e7          	jalr	1114(ra) # 80002cc0 <argint>
    8000586e:	0a054863          	bltz	a0,8000591e <sys_open+0xe4>

  begin_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	a2e080e7          	jalr	-1490(ra) # 800042a0 <begin_op>

  if(omode & O_CREATE){
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	2007f793          	andi	a5,a5,512
    80005882:	cbdd                	beqz	a5,80005938 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005884:	4681                	li	a3,0
    80005886:	4601                	li	a2,0
    80005888:	4589                	li	a1,2
    8000588a:	f5040513          	addi	a0,s0,-176
    8000588e:	00000097          	auipc	ra,0x0
    80005892:	972080e7          	jalr	-1678(ra) # 80005200 <create>
    80005896:	892a                	mv	s2,a0
    if(ip == 0){
    80005898:	c959                	beqz	a0,8000592e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	478d                	li	a5,3
    800058a0:	00f71763          	bne	a4,a5,800058ae <sys_open+0x74>
    800058a4:	04695703          	lhu	a4,70(s2)
    800058a8:	47a5                	li	a5,9
    800058aa:	0ce7ec63          	bltu	a5,a4,80005982 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	e02080e7          	jalr	-510(ra) # 800046b0 <filealloc>
    800058b6:	89aa                	mv	s3,a0
    800058b8:	10050263          	beqz	a0,800059bc <sys_open+0x182>
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	902080e7          	jalr	-1790(ra) # 800051be <fdalloc>
    800058c4:	84aa                	mv	s1,a0
    800058c6:	0e054663          	bltz	a0,800059b2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058ca:	04491703          	lh	a4,68(s2)
    800058ce:	478d                	li	a5,3
    800058d0:	0cf70463          	beq	a4,a5,80005998 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d4:	4789                	li	a5,2
    800058d6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058da:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058de:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e2:	f4c42783          	lw	a5,-180(s0)
    800058e6:	0017c713          	xori	a4,a5,1
    800058ea:	8b05                	andi	a4,a4,1
    800058ec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f0:	0037f713          	andi	a4,a5,3
    800058f4:	00e03733          	snez	a4,a4
    800058f8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058fc:	4007f793          	andi	a5,a5,1024
    80005900:	c791                	beqz	a5,8000590c <sys_open+0xd2>
    80005902:	04491703          	lh	a4,68(s2)
    80005906:	4789                	li	a5,2
    80005908:	08f70f63          	beq	a4,a5,800059a6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	082080e7          	jalr	130(ra) # 80003990 <iunlock>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	a0a080e7          	jalr	-1526(ra) # 80004320 <end_op>

  return fd;
}
    8000591e:	8526                	mv	a0,s1
    80005920:	70ea                	ld	ra,184(sp)
    80005922:	744a                	ld	s0,176(sp)
    80005924:	74aa                	ld	s1,168(sp)
    80005926:	790a                	ld	s2,160(sp)
    80005928:	69ea                	ld	s3,152(sp)
    8000592a:	6129                	addi	sp,sp,192
    8000592c:	8082                	ret
      end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	9f2080e7          	jalr	-1550(ra) # 80004320 <end_op>
      return -1;
    80005936:	b7e5                	j	8000591e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005938:	f5040513          	addi	a0,s0,-176
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	748080e7          	jalr	1864(ra) # 80004084 <namei>
    80005944:	892a                	mv	s2,a0
    80005946:	c905                	beqz	a0,80005976 <sys_open+0x13c>
    ilock(ip);
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	f86080e7          	jalr	-122(ra) # 800038ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005950:	04491703          	lh	a4,68(s2)
    80005954:	4785                	li	a5,1
    80005956:	f4f712e3          	bne	a4,a5,8000589a <sys_open+0x60>
    8000595a:	f4c42783          	lw	a5,-180(s0)
    8000595e:	dba1                	beqz	a5,800058ae <sys_open+0x74>
      iunlockput(ip);
    80005960:	854a                	mv	a0,s2
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	1ce080e7          	jalr	462(ra) # 80003b30 <iunlockput>
      end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	9b6080e7          	jalr	-1610(ra) # 80004320 <end_op>
      return -1;
    80005972:	54fd                	li	s1,-1
    80005974:	b76d                	j	8000591e <sys_open+0xe4>
      end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	9aa080e7          	jalr	-1622(ra) # 80004320 <end_op>
      return -1;
    8000597e:	54fd                	li	s1,-1
    80005980:	bf79                	j	8000591e <sys_open+0xe4>
    iunlockput(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	1ac080e7          	jalr	428(ra) # 80003b30 <iunlockput>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	994080e7          	jalr	-1644(ra) # 80004320 <end_op>
    return -1;
    80005994:	54fd                	li	s1,-1
    80005996:	b761                	j	8000591e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005998:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000599c:	04691783          	lh	a5,70(s2)
    800059a0:	02f99223          	sh	a5,36(s3)
    800059a4:	bf2d                	j	800058de <sys_open+0xa4>
    itrunc(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	034080e7          	jalr	52(ra) # 800039dc <itrunc>
    800059b0:	bfb1                	j	8000590c <sys_open+0xd2>
      fileclose(f);
    800059b2:	854e                	mv	a0,s3
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	db8080e7          	jalr	-584(ra) # 8000476c <fileclose>
    iunlockput(ip);
    800059bc:	854a                	mv	a0,s2
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	172080e7          	jalr	370(ra) # 80003b30 <iunlockput>
    end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	95a080e7          	jalr	-1702(ra) # 80004320 <end_op>
    return -1;
    800059ce:	54fd                	li	s1,-1
    800059d0:	b7b9                	j	8000591e <sys_open+0xe4>

00000000800059d2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d2:	7175                	addi	sp,sp,-144
    800059d4:	e506                	sd	ra,136(sp)
    800059d6:	e122                	sd	s0,128(sp)
    800059d8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	8c6080e7          	jalr	-1850(ra) # 800042a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e2:	08000613          	li	a2,128
    800059e6:	f7040593          	addi	a1,s0,-144
    800059ea:	4501                	li	a0,0
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	318080e7          	jalr	792(ra) # 80002d04 <argstr>
    800059f4:	02054963          	bltz	a0,80005a26 <sys_mkdir+0x54>
    800059f8:	4681                	li	a3,0
    800059fa:	4601                	li	a2,0
    800059fc:	4585                	li	a1,1
    800059fe:	f7040513          	addi	a0,s0,-144
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	7fe080e7          	jalr	2046(ra) # 80005200 <create>
    80005a0a:	cd11                	beqz	a0,80005a26 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	124080e7          	jalr	292(ra) # 80003b30 <iunlockput>
  end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	90c080e7          	jalr	-1780(ra) # 80004320 <end_op>
  return 0;
    80005a1c:	4501                	li	a0,0
}
    80005a1e:	60aa                	ld	ra,136(sp)
    80005a20:	640a                	ld	s0,128(sp)
    80005a22:	6149                	addi	sp,sp,144
    80005a24:	8082                	ret
    end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	8fa080e7          	jalr	-1798(ra) # 80004320 <end_op>
    return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	b7fd                	j	80005a1e <sys_mkdir+0x4c>

0000000080005a32 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a32:	7135                	addi	sp,sp,-160
    80005a34:	ed06                	sd	ra,152(sp)
    80005a36:	e922                	sd	s0,144(sp)
    80005a38:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	866080e7          	jalr	-1946(ra) # 800042a0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a42:	08000613          	li	a2,128
    80005a46:	f7040593          	addi	a1,s0,-144
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	2b8080e7          	jalr	696(ra) # 80002d04 <argstr>
    80005a54:	04054a63          	bltz	a0,80005aa8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a58:	f6c40593          	addi	a1,s0,-148
    80005a5c:	4505                	li	a0,1
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	262080e7          	jalr	610(ra) # 80002cc0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a66:	04054163          	bltz	a0,80005aa8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6a:	f6840593          	addi	a1,s0,-152
    80005a6e:	4509                	li	a0,2
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	250080e7          	jalr	592(ra) # 80002cc0 <argint>
     argint(1, &major) < 0 ||
    80005a78:	02054863          	bltz	a0,80005aa8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7c:	f6841683          	lh	a3,-152(s0)
    80005a80:	f6c41603          	lh	a2,-148(s0)
    80005a84:	458d                	li	a1,3
    80005a86:	f7040513          	addi	a0,s0,-144
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	776080e7          	jalr	1910(ra) # 80005200 <create>
     argint(2, &minor) < 0 ||
    80005a92:	c919                	beqz	a0,80005aa8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	09c080e7          	jalr	156(ra) # 80003b30 <iunlockput>
  end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	884080e7          	jalr	-1916(ra) # 80004320 <end_op>
  return 0;
    80005aa4:	4501                	li	a0,0
    80005aa6:	a031                	j	80005ab2 <sys_mknod+0x80>
    end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	878080e7          	jalr	-1928(ra) # 80004320 <end_op>
    return -1;
    80005ab0:	557d                	li	a0,-1
}
    80005ab2:	60ea                	ld	ra,152(sp)
    80005ab4:	644a                	ld	s0,144(sp)
    80005ab6:	610d                	addi	sp,sp,160
    80005ab8:	8082                	ret

0000000080005aba <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aba:	7135                	addi	sp,sp,-160
    80005abc:	ed06                	sd	ra,152(sp)
    80005abe:	e922                	sd	s0,144(sp)
    80005ac0:	e526                	sd	s1,136(sp)
    80005ac2:	e14a                	sd	s2,128(sp)
    80005ac4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac6:	ffffc097          	auipc	ra,0xffffc
    80005aca:	eea080e7          	jalr	-278(ra) # 800019b0 <myproc>
    80005ace:	892a                	mv	s2,a0
  
  begin_op();
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	7d0080e7          	jalr	2000(ra) # 800042a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ad8:	08000613          	li	a2,128
    80005adc:	f6040593          	addi	a1,s0,-160
    80005ae0:	4501                	li	a0,0
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	222080e7          	jalr	546(ra) # 80002d04 <argstr>
    80005aea:	04054b63          	bltz	a0,80005b40 <sys_chdir+0x86>
    80005aee:	f6040513          	addi	a0,s0,-160
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	592080e7          	jalr	1426(ra) # 80004084 <namei>
    80005afa:	84aa                	mv	s1,a0
    80005afc:	c131                	beqz	a0,80005b40 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	dd0080e7          	jalr	-560(ra) # 800038ce <ilock>
  if(ip->type != T_DIR){
    80005b06:	04449703          	lh	a4,68(s1)
    80005b0a:	4785                	li	a5,1
    80005b0c:	04f71063          	bne	a4,a5,80005b4c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	e7e080e7          	jalr	-386(ra) # 80003990 <iunlock>
  iput(p->cwd);
    80005b1a:	15093503          	ld	a0,336(s2)
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	f6a080e7          	jalr	-150(ra) # 80003a88 <iput>
  end_op();
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	7fa080e7          	jalr	2042(ra) # 80004320 <end_op>
  p->cwd = ip;
    80005b2e:	14993823          	sd	s1,336(s2)
  return 0;
    80005b32:	4501                	li	a0,0
}
    80005b34:	60ea                	ld	ra,152(sp)
    80005b36:	644a                	ld	s0,144(sp)
    80005b38:	64aa                	ld	s1,136(sp)
    80005b3a:	690a                	ld	s2,128(sp)
    80005b3c:	610d                	addi	sp,sp,160
    80005b3e:	8082                	ret
    end_op();
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	7e0080e7          	jalr	2016(ra) # 80004320 <end_op>
    return -1;
    80005b48:	557d                	li	a0,-1
    80005b4a:	b7ed                	j	80005b34 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	fe2080e7          	jalr	-30(ra) # 80003b30 <iunlockput>
    end_op();
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	7ca080e7          	jalr	1994(ra) # 80004320 <end_op>
    return -1;
    80005b5e:	557d                	li	a0,-1
    80005b60:	bfd1                	j	80005b34 <sys_chdir+0x7a>

0000000080005b62 <sys_exec>:

uint64
sys_exec(void)
{
    80005b62:	7145                	addi	sp,sp,-464
    80005b64:	e786                	sd	ra,456(sp)
    80005b66:	e3a2                	sd	s0,448(sp)
    80005b68:	ff26                	sd	s1,440(sp)
    80005b6a:	fb4a                	sd	s2,432(sp)
    80005b6c:	f74e                	sd	s3,424(sp)
    80005b6e:	f352                	sd	s4,416(sp)
    80005b70:	ef56                	sd	s5,408(sp)
    80005b72:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b74:	08000613          	li	a2,128
    80005b78:	f4040593          	addi	a1,s0,-192
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	186080e7          	jalr	390(ra) # 80002d04 <argstr>
    return -1;
    80005b86:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b88:	0c054a63          	bltz	a0,80005c5c <sys_exec+0xfa>
    80005b8c:	e3840593          	addi	a1,s0,-456
    80005b90:	4505                	li	a0,1
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	150080e7          	jalr	336(ra) # 80002ce2 <argaddr>
    80005b9a:	0c054163          	bltz	a0,80005c5c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b9e:	10000613          	li	a2,256
    80005ba2:	4581                	li	a1,0
    80005ba4:	e4040513          	addi	a0,s0,-448
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	138080e7          	jalr	312(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb4:	89a6                	mv	s3,s1
    80005bb6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bb8:	02000a13          	li	s4,32
    80005bbc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc0:	00391513          	slli	a0,s2,0x3
    80005bc4:	e3040593          	addi	a1,s0,-464
    80005bc8:	e3843783          	ld	a5,-456(s0)
    80005bcc:	953e                	add	a0,a0,a5
    80005bce:	ffffd097          	auipc	ra,0xffffd
    80005bd2:	058080e7          	jalr	88(ra) # 80002c26 <fetchaddr>
    80005bd6:	02054a63          	bltz	a0,80005c0a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bda:	e3043783          	ld	a5,-464(s0)
    80005bde:	c3b9                	beqz	a5,80005c24 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be0:	ffffb097          	auipc	ra,0xffffb
    80005be4:	f14080e7          	jalr	-236(ra) # 80000af4 <kalloc>
    80005be8:	85aa                	mv	a1,a0
    80005bea:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bee:	cd11                	beqz	a0,80005c0a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf0:	6605                	lui	a2,0x1
    80005bf2:	e3043503          	ld	a0,-464(s0)
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	082080e7          	jalr	130(ra) # 80002c78 <fetchstr>
    80005bfe:	00054663          	bltz	a0,80005c0a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c02:	0905                	addi	s2,s2,1
    80005c04:	09a1                	addi	s3,s3,8
    80005c06:	fb491be3          	bne	s2,s4,80005bbc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0a:	10048913          	addi	s2,s1,256
    80005c0e:	6088                	ld	a0,0(s1)
    80005c10:	c529                	beqz	a0,80005c5a <sys_exec+0xf8>
    kfree(argv[i]);
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	de6080e7          	jalr	-538(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	04a1                	addi	s1,s1,8
    80005c1c:	ff2499e3          	bne	s1,s2,80005c0e <sys_exec+0xac>
  return -1;
    80005c20:	597d                	li	s2,-1
    80005c22:	a82d                	j	80005c5c <sys_exec+0xfa>
      argv[i] = 0;
    80005c24:	0a8e                	slli	s5,s5,0x3
    80005c26:	fc040793          	addi	a5,s0,-64
    80005c2a:	9abe                	add	s5,s5,a5
    80005c2c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c30:	e4040593          	addi	a1,s0,-448
    80005c34:	f4040513          	addi	a0,s0,-192
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	194080e7          	jalr	404(ra) # 80004dcc <exec>
    80005c40:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c42:	10048993          	addi	s3,s1,256
    80005c46:	6088                	ld	a0,0(s1)
    80005c48:	c911                	beqz	a0,80005c5c <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	dae080e7          	jalr	-594(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	04a1                	addi	s1,s1,8
    80005c54:	ff3499e3          	bne	s1,s3,80005c46 <sys_exec+0xe4>
    80005c58:	a011                	j	80005c5c <sys_exec+0xfa>
  return -1;
    80005c5a:	597d                	li	s2,-1
}
    80005c5c:	854a                	mv	a0,s2
    80005c5e:	60be                	ld	ra,456(sp)
    80005c60:	641e                	ld	s0,448(sp)
    80005c62:	74fa                	ld	s1,440(sp)
    80005c64:	795a                	ld	s2,432(sp)
    80005c66:	79ba                	ld	s3,424(sp)
    80005c68:	7a1a                	ld	s4,416(sp)
    80005c6a:	6afa                	ld	s5,408(sp)
    80005c6c:	6179                	addi	sp,sp,464
    80005c6e:	8082                	ret

0000000080005c70 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c70:	7139                	addi	sp,sp,-64
    80005c72:	fc06                	sd	ra,56(sp)
    80005c74:	f822                	sd	s0,48(sp)
    80005c76:	f426                	sd	s1,40(sp)
    80005c78:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7a:	ffffc097          	auipc	ra,0xffffc
    80005c7e:	d36080e7          	jalr	-714(ra) # 800019b0 <myproc>
    80005c82:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c84:	fd840593          	addi	a1,s0,-40
    80005c88:	4501                	li	a0,0
    80005c8a:	ffffd097          	auipc	ra,0xffffd
    80005c8e:	058080e7          	jalr	88(ra) # 80002ce2 <argaddr>
    return -1;
    80005c92:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c94:	0e054063          	bltz	a0,80005d74 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c98:	fc840593          	addi	a1,s0,-56
    80005c9c:	fd040513          	addi	a0,s0,-48
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	dfc080e7          	jalr	-516(ra) # 80004a9c <pipealloc>
    return -1;
    80005ca8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005caa:	0c054563          	bltz	a0,80005d74 <sys_pipe+0x104>
  fd0 = -1;
    80005cae:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb2:	fd043503          	ld	a0,-48(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	508080e7          	jalr	1288(ra) # 800051be <fdalloc>
    80005cbe:	fca42223          	sw	a0,-60(s0)
    80005cc2:	08054c63          	bltz	a0,80005d5a <sys_pipe+0xea>
    80005cc6:	fc843503          	ld	a0,-56(s0)
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	4f4080e7          	jalr	1268(ra) # 800051be <fdalloc>
    80005cd2:	fca42023          	sw	a0,-64(s0)
    80005cd6:	06054863          	bltz	a0,80005d46 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cda:	4691                	li	a3,4
    80005cdc:	fc440613          	addi	a2,s0,-60
    80005ce0:	fd843583          	ld	a1,-40(s0)
    80005ce4:	68a8                	ld	a0,80(s1)
    80005ce6:	ffffc097          	auipc	ra,0xffffc
    80005cea:	98c080e7          	jalr	-1652(ra) # 80001672 <copyout>
    80005cee:	02054063          	bltz	a0,80005d0e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf2:	4691                	li	a3,4
    80005cf4:	fc040613          	addi	a2,s0,-64
    80005cf8:	fd843583          	ld	a1,-40(s0)
    80005cfc:	0591                	addi	a1,a1,4
    80005cfe:	68a8                	ld	a0,80(s1)
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	972080e7          	jalr	-1678(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d08:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0a:	06055563          	bgez	a0,80005d74 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d0e:	fc442783          	lw	a5,-60(s0)
    80005d12:	07e9                	addi	a5,a5,26
    80005d14:	078e                	slli	a5,a5,0x3
    80005d16:	97a6                	add	a5,a5,s1
    80005d18:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1c:	fc042503          	lw	a0,-64(s0)
    80005d20:	0569                	addi	a0,a0,26
    80005d22:	050e                	slli	a0,a0,0x3
    80005d24:	9526                	add	a0,a0,s1
    80005d26:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d2a:	fd043503          	ld	a0,-48(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	a3e080e7          	jalr	-1474(ra) # 8000476c <fileclose>
    fileclose(wf);
    80005d36:	fc843503          	ld	a0,-56(s0)
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	a32080e7          	jalr	-1486(ra) # 8000476c <fileclose>
    return -1;
    80005d42:	57fd                	li	a5,-1
    80005d44:	a805                	j	80005d74 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d46:	fc442783          	lw	a5,-60(s0)
    80005d4a:	0007c863          	bltz	a5,80005d5a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d4e:	01a78513          	addi	a0,a5,26
    80005d52:	050e                	slli	a0,a0,0x3
    80005d54:	9526                	add	a0,a0,s1
    80005d56:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d5a:	fd043503          	ld	a0,-48(s0)
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	a0e080e7          	jalr	-1522(ra) # 8000476c <fileclose>
    fileclose(wf);
    80005d66:	fc843503          	ld	a0,-56(s0)
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	a02080e7          	jalr	-1534(ra) # 8000476c <fileclose>
    return -1;
    80005d72:	57fd                	li	a5,-1
}
    80005d74:	853e                	mv	a0,a5
    80005d76:	70e2                	ld	ra,56(sp)
    80005d78:	7442                	ld	s0,48(sp)
    80005d7a:	74a2                	ld	s1,40(sp)
    80005d7c:	6121                	addi	sp,sp,64
    80005d7e:	8082                	ret

0000000080005d80 <kernelvec>:
    80005d80:	7111                	addi	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	d33fc0ef          	jal	ra,80002af2 <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	addi	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	addi	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	addi	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b2c080e7          	jalr	-1236(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	slliw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	slliw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	953e                	add	a0,a0,a5
    80005e7c:	00052023          	sw	zero,0(a0)
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	addi	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	af4080e7          	jalr	-1292(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5179b          	slliw	a5,a0,0xd
    80005e9c:	0c201537          	lui	a0,0xc201
    80005ea0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ea2:	4148                	lw	a0,4(a0)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	addi	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	addi	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	acc080e7          	jalr	-1332(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	slliw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	addi	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	addi	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	06a7c963          	blt	a5,a0,80005f52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	0001d797          	auipc	a5,0x1d
    80005ee8:	11c78793          	addi	a5,a5,284 # 80023000 <disk>
    80005eec:	00a78733          	add	a4,a5,a0
    80005ef0:	6789                	lui	a5,0x2
    80005ef2:	97ba                	add	a5,a5,a4
    80005ef4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ef8:	e7ad                	bnez	a5,80005f62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005efa:	00451793          	slli	a5,a0,0x4
    80005efe:	0001f717          	auipc	a4,0x1f
    80005f02:	10270713          	addi	a4,a4,258 # 80025000 <disk+0x2000>
    80005f06:	6314                	ld	a3,0(a4)
    80005f08:	96be                	add	a3,a3,a5
    80005f0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f0e:	6314                	ld	a3,0(a4)
    80005f10:	96be                	add	a3,a3,a5
    80005f12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f1e:	6318                	ld	a4,0(a4)
    80005f20:	97ba                	add	a5,a5,a4
    80005f22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f26:	0001d797          	auipc	a5,0x1d
    80005f2a:	0da78793          	addi	a5,a5,218 # 80023000 <disk>
    80005f2e:	97aa                	add	a5,a5,a0
    80005f30:	6509                	lui	a0,0x2
    80005f32:	953e                	add	a0,a0,a5
    80005f34:	4785                	li	a5,1
    80005f36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f3a:	0001f517          	auipc	a0,0x1f
    80005f3e:	0de50513          	addi	a0,a0,222 # 80025018 <disk+0x2018>
    80005f42:	ffffc097          	auipc	ra,0xffffc
    80005f46:	460080e7          	jalr	1120(ra) # 800023a2 <wakeup>
}
    80005f4a:	60a2                	ld	ra,8(sp)
    80005f4c:	6402                	ld	s0,0(sp)
    80005f4e:	0141                	addi	sp,sp,16
    80005f50:	8082                	ret
    panic("free_desc 1");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	83e50513          	addi	a0,a0,-1986 # 80008790 <syscalls+0x330>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	83e50513          	addi	a0,a0,-1986 # 800087a0 <syscalls+0x340>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>

0000000080005f72 <virtio_disk_init>:
{
    80005f72:	1101                	addi	sp,sp,-32
    80005f74:	ec06                	sd	ra,24(sp)
    80005f76:	e822                	sd	s0,16(sp)
    80005f78:	e426                	sd	s1,8(sp)
    80005f7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f7c:	00003597          	auipc	a1,0x3
    80005f80:	83458593          	addi	a1,a1,-1996 # 800087b0 <syscalls+0x350>
    80005f84:	0001f517          	auipc	a0,0x1f
    80005f88:	1a450513          	addi	a0,a0,420 # 80025128 <disk+0x2128>
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	bc8080e7          	jalr	-1080(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f94:	100017b7          	lui	a5,0x10001
    80005f98:	4398                	lw	a4,0(a5)
    80005f9a:	2701                	sext.w	a4,a4
    80005f9c:	747277b7          	lui	a5,0x74727
    80005fa0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fa4:	0ef71163          	bne	a4,a5,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	43dc                	lw	a5,4(a5)
    80005fae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fb0:	4705                	li	a4,1
    80005fb2:	0ce79a63          	bne	a5,a4,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb6:	100017b7          	lui	a5,0x10001
    80005fba:	479c                	lw	a5,8(a5)
    80005fbc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fbe:	4709                	li	a4,2
    80005fc0:	0ce79363          	bne	a5,a4,80006086 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fc4:	100017b7          	lui	a5,0x10001
    80005fc8:	47d8                	lw	a4,12(a5)
    80005fca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fcc:	554d47b7          	lui	a5,0x554d4
    80005fd0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fd4:	0af71963          	bne	a4,a5,80006086 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd8:	100017b7          	lui	a5,0x10001
    80005fdc:	4705                	li	a4,1
    80005fde:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe0:	470d                	li	a4,3
    80005fe2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fe4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fe6:	c7ffe737          	lui	a4,0xc7ffe
    80005fea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ff0:	2701                	sext.w	a4,a4
    80005ff2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff4:	472d                	li	a4,11
    80005ff6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	473d                	li	a4,15
    80005ffa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ffc:	6705                	lui	a4,0x1
    80005ffe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006000:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006004:	5bdc                	lw	a5,52(a5)
    80006006:	2781                	sext.w	a5,a5
  if(max == 0)
    80006008:	c7d9                	beqz	a5,80006096 <virtio_disk_init+0x124>
  if(max < NUM)
    8000600a:	471d                	li	a4,7
    8000600c:	08f77d63          	bgeu	a4,a5,800060a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006010:	100014b7          	lui	s1,0x10001
    80006014:	47a1                	li	a5,8
    80006016:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006018:	6609                	lui	a2,0x2
    8000601a:	4581                	li	a1,0
    8000601c:	0001d517          	auipc	a0,0x1d
    80006020:	fe450513          	addi	a0,a0,-28 # 80023000 <disk>
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	cbc080e7          	jalr	-836(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000602c:	0001d717          	auipc	a4,0x1d
    80006030:	fd470713          	addi	a4,a4,-44 # 80023000 <disk>
    80006034:	00c75793          	srli	a5,a4,0xc
    80006038:	2781                	sext.w	a5,a5
    8000603a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000603c:	0001f797          	auipc	a5,0x1f
    80006040:	fc478793          	addi	a5,a5,-60 # 80025000 <disk+0x2000>
    80006044:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006046:	0001d717          	auipc	a4,0x1d
    8000604a:	03a70713          	addi	a4,a4,58 # 80023080 <disk+0x80>
    8000604e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006050:	0001e717          	auipc	a4,0x1e
    80006054:	fb070713          	addi	a4,a4,-80 # 80024000 <disk+0x1000>
    80006058:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000605a:	4705                	li	a4,1
    8000605c:	00e78c23          	sb	a4,24(a5)
    80006060:	00e78ca3          	sb	a4,25(a5)
    80006064:	00e78d23          	sb	a4,26(a5)
    80006068:	00e78da3          	sb	a4,27(a5)
    8000606c:	00e78e23          	sb	a4,28(a5)
    80006070:	00e78ea3          	sb	a4,29(a5)
    80006074:	00e78f23          	sb	a4,30(a5)
    80006078:	00e78fa3          	sb	a4,31(a5)
}
    8000607c:	60e2                	ld	ra,24(sp)
    8000607e:	6442                	ld	s0,16(sp)
    80006080:	64a2                	ld	s1,8(sp)
    80006082:	6105                	addi	sp,sp,32
    80006084:	8082                	ret
    panic("could not find virtio disk");
    80006086:	00002517          	auipc	a0,0x2
    8000608a:	73a50513          	addi	a0,a0,1850 # 800087c0 <syscalls+0x360>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	74a50513          	addi	a0,a0,1866 # 800087e0 <syscalls+0x380>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	75a50513          	addi	a0,a0,1882 # 80008800 <syscalls+0x3a0>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>

00000000800060b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060b6:	7159                	addi	sp,sp,-112
    800060b8:	f486                	sd	ra,104(sp)
    800060ba:	f0a2                	sd	s0,96(sp)
    800060bc:	eca6                	sd	s1,88(sp)
    800060be:	e8ca                	sd	s2,80(sp)
    800060c0:	e4ce                	sd	s3,72(sp)
    800060c2:	e0d2                	sd	s4,64(sp)
    800060c4:	fc56                	sd	s5,56(sp)
    800060c6:	f85a                	sd	s6,48(sp)
    800060c8:	f45e                	sd	s7,40(sp)
    800060ca:	f062                	sd	s8,32(sp)
    800060cc:	ec66                	sd	s9,24(sp)
    800060ce:	e86a                	sd	s10,16(sp)
    800060d0:	1880                	addi	s0,sp,112
    800060d2:	892a                	mv	s2,a0
    800060d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060d6:	00c52c83          	lw	s9,12(a0)
    800060da:	001c9c9b          	slliw	s9,s9,0x1
    800060de:	1c82                	slli	s9,s9,0x20
    800060e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060e4:	0001f517          	auipc	a0,0x1f
    800060e8:	04450513          	addi	a0,a0,68 # 80025128 <disk+0x2128>
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	af8080e7          	jalr	-1288(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060f8:	0001db97          	auipc	s7,0x1d
    800060fc:	f08b8b93          	addi	s7,s7,-248 # 80023000 <disk>
    80006100:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006102:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006104:	8a4e                	mv	s4,s3
    80006106:	a051                	j	8000618a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006108:	00fb86b3          	add	a3,s7,a5
    8000610c:	96da                	add	a3,a3,s6
    8000610e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006112:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006114:	0207c563          	bltz	a5,8000613e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006118:	2485                	addiw	s1,s1,1
    8000611a:	0711                	addi	a4,a4,4
    8000611c:	25548063          	beq	s1,s5,8000635c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006120:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006122:	0001f697          	auipc	a3,0x1f
    80006126:	ef668693          	addi	a3,a3,-266 # 80025018 <disk+0x2018>
    8000612a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000612c:	0006c583          	lbu	a1,0(a3)
    80006130:	fde1                	bnez	a1,80006108 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006132:	2785                	addiw	a5,a5,1
    80006134:	0685                	addi	a3,a3,1
    80006136:	ff879be3          	bne	a5,s8,8000612c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000613a:	57fd                	li	a5,-1
    8000613c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000613e:	02905a63          	blez	s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006142:	f9042503          	lw	a0,-112(s0)
    80006146:	00000097          	auipc	ra,0x0
    8000614a:	d90080e7          	jalr	-624(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    8000614e:	4785                	li	a5,1
    80006150:	0297d163          	bge	a5,s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006154:	f9442503          	lw	a0,-108(s0)
    80006158:	00000097          	auipc	ra,0x0
    8000615c:	d7e080e7          	jalr	-642(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    80006160:	4789                	li	a5,2
    80006162:	0097d863          	bge	a5,s1,80006172 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006166:	f9842503          	lw	a0,-104(s0)
    8000616a:	00000097          	auipc	ra,0x0
    8000616e:	d6c080e7          	jalr	-660(ra) # 80005ed6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006172:	0001f597          	auipc	a1,0x1f
    80006176:	fb658593          	addi	a1,a1,-74 # 80025128 <disk+0x2128>
    8000617a:	0001f517          	auipc	a0,0x1f
    8000617e:	e9e50513          	addi	a0,a0,-354 # 80025018 <disk+0x2018>
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	08a080e7          	jalr	138(ra) # 8000220c <sleep>
  for(int i = 0; i < 3; i++){
    8000618a:	f9040713          	addi	a4,s0,-112
    8000618e:	84ce                	mv	s1,s3
    80006190:	bf41                	j	80006120 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006192:	20058713          	addi	a4,a1,512
    80006196:	00471693          	slli	a3,a4,0x4
    8000619a:	0001d717          	auipc	a4,0x1d
    8000619e:	e6670713          	addi	a4,a4,-410 # 80023000 <disk>
    800061a2:	9736                	add	a4,a4,a3
    800061a4:	4685                	li	a3,1
    800061a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061aa:	20058713          	addi	a4,a1,512
    800061ae:	00471693          	slli	a3,a4,0x4
    800061b2:	0001d717          	auipc	a4,0x1d
    800061b6:	e4e70713          	addi	a4,a4,-434 # 80023000 <disk>
    800061ba:	9736                	add	a4,a4,a3
    800061bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061c4:	7679                	lui	a2,0xffffe
    800061c6:	963e                	add	a2,a2,a5
    800061c8:	0001f697          	auipc	a3,0x1f
    800061cc:	e3868693          	addi	a3,a3,-456 # 80025000 <disk+0x2000>
    800061d0:	6298                	ld	a4,0(a3)
    800061d2:	9732                	add	a4,a4,a2
    800061d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061d6:	6298                	ld	a4,0(a3)
    800061d8:	9732                	add	a4,a4,a2
    800061da:	4541                	li	a0,16
    800061dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061de:	6298                	ld	a4,0(a3)
    800061e0:	9732                	add	a4,a4,a2
    800061e2:	4505                	li	a0,1
    800061e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061e8:	f9442703          	lw	a4,-108(s0)
    800061ec:	6288                	ld	a0,0(a3)
    800061ee:	962a                	add	a2,a2,a0
    800061f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f4:	0712                	slli	a4,a4,0x4
    800061f6:	6290                	ld	a2,0(a3)
    800061f8:	963a                	add	a2,a2,a4
    800061fa:	05890513          	addi	a0,s2,88
    800061fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006200:	6294                	ld	a3,0(a3)
    80006202:	96ba                	add	a3,a3,a4
    80006204:	40000613          	li	a2,1024
    80006208:	c690                	sw	a2,8(a3)
  if(write)
    8000620a:	140d0063          	beqz	s10,8000634a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000620e:	0001f697          	auipc	a3,0x1f
    80006212:	df26b683          	ld	a3,-526(a3) # 80025000 <disk+0x2000>
    80006216:	96ba                	add	a3,a3,a4
    80006218:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000621c:	0001d817          	auipc	a6,0x1d
    80006220:	de480813          	addi	a6,a6,-540 # 80023000 <disk>
    80006224:	0001f517          	auipc	a0,0x1f
    80006228:	ddc50513          	addi	a0,a0,-548 # 80025000 <disk+0x2000>
    8000622c:	6114                	ld	a3,0(a0)
    8000622e:	96ba                	add	a3,a3,a4
    80006230:	00c6d603          	lhu	a2,12(a3)
    80006234:	00166613          	ori	a2,a2,1
    80006238:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000623c:	f9842683          	lw	a3,-104(s0)
    80006240:	6110                	ld	a2,0(a0)
    80006242:	9732                	add	a4,a4,a2
    80006244:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006248:	20058613          	addi	a2,a1,512
    8000624c:	0612                	slli	a2,a2,0x4
    8000624e:	9642                	add	a2,a2,a6
    80006250:	577d                	li	a4,-1
    80006252:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006256:	00469713          	slli	a4,a3,0x4
    8000625a:	6114                	ld	a3,0(a0)
    8000625c:	96ba                	add	a3,a3,a4
    8000625e:	03078793          	addi	a5,a5,48
    80006262:	97c2                	add	a5,a5,a6
    80006264:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006266:	611c                	ld	a5,0(a0)
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	4685                	li	a3,1
    8000626c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000626e:	611c                	ld	a5,0(a0)
    80006270:	97ba                	add	a5,a5,a4
    80006272:	4809                	li	a6,2
    80006274:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006278:	611c                	ld	a5,0(a0)
    8000627a:	973e                	add	a4,a4,a5
    8000627c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006280:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006284:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006288:	6518                	ld	a4,8(a0)
    8000628a:	00275783          	lhu	a5,2(a4)
    8000628e:	8b9d                	andi	a5,a5,7
    80006290:	0786                	slli	a5,a5,0x1
    80006292:	97ba                	add	a5,a5,a4
    80006294:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006298:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000629c:	6518                	ld	a4,8(a0)
    8000629e:	00275783          	lhu	a5,2(a4)
    800062a2:	2785                	addiw	a5,a5,1
    800062a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ac:	100017b7          	lui	a5,0x10001
    800062b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062b4:	00492703          	lw	a4,4(s2)
    800062b8:	4785                	li	a5,1
    800062ba:	02f71163          	bne	a4,a5,800062dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062be:	0001f997          	auipc	s3,0x1f
    800062c2:	e6a98993          	addi	s3,s3,-406 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062c8:	85ce                	mv	a1,s3
    800062ca:	854a                	mv	a0,s2
    800062cc:	ffffc097          	auipc	ra,0xffffc
    800062d0:	f40080e7          	jalr	-192(ra) # 8000220c <sleep>
  while(b->disk == 1) {
    800062d4:	00492783          	lw	a5,4(s2)
    800062d8:	fe9788e3          	beq	a5,s1,800062c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062dc:	f9042903          	lw	s2,-112(s0)
    800062e0:	20090793          	addi	a5,s2,512
    800062e4:	00479713          	slli	a4,a5,0x4
    800062e8:	0001d797          	auipc	a5,0x1d
    800062ec:	d1878793          	addi	a5,a5,-744 # 80023000 <disk>
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062f6:	0001f997          	auipc	s3,0x1f
    800062fa:	d0a98993          	addi	s3,s3,-758 # 80025000 <disk+0x2000>
    800062fe:	00491713          	slli	a4,s2,0x4
    80006302:	0009b783          	ld	a5,0(s3)
    80006306:	97ba                	add	a5,a5,a4
    80006308:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000630c:	854a                	mv	a0,s2
    8000630e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006312:	00000097          	auipc	ra,0x0
    80006316:	bc4080e7          	jalr	-1084(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000631a:	8885                	andi	s1,s1,1
    8000631c:	f0ed                	bnez	s1,800062fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000631e:	0001f517          	auipc	a0,0x1f
    80006322:	e0a50513          	addi	a0,a0,-502 # 80025128 <disk+0x2128>
    80006326:	ffffb097          	auipc	ra,0xffffb
    8000632a:	972080e7          	jalr	-1678(ra) # 80000c98 <release>
}
    8000632e:	70a6                	ld	ra,104(sp)
    80006330:	7406                	ld	s0,96(sp)
    80006332:	64e6                	ld	s1,88(sp)
    80006334:	6946                	ld	s2,80(sp)
    80006336:	69a6                	ld	s3,72(sp)
    80006338:	6a06                	ld	s4,64(sp)
    8000633a:	7ae2                	ld	s5,56(sp)
    8000633c:	7b42                	ld	s6,48(sp)
    8000633e:	7ba2                	ld	s7,40(sp)
    80006340:	7c02                	ld	s8,32(sp)
    80006342:	6ce2                	ld	s9,24(sp)
    80006344:	6d42                	ld	s10,16(sp)
    80006346:	6165                	addi	sp,sp,112
    80006348:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000634a:	0001f697          	auipc	a3,0x1f
    8000634e:	cb66b683          	ld	a3,-842(a3) # 80025000 <disk+0x2000>
    80006352:	96ba                	add	a3,a3,a4
    80006354:	4609                	li	a2,2
    80006356:	00c69623          	sh	a2,12(a3)
    8000635a:	b5c9                	j	8000621c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000635c:	f9042583          	lw	a1,-112(s0)
    80006360:	20058793          	addi	a5,a1,512
    80006364:	0792                	slli	a5,a5,0x4
    80006366:	0001d517          	auipc	a0,0x1d
    8000636a:	d4250513          	addi	a0,a0,-702 # 800230a8 <disk+0xa8>
    8000636e:	953e                	add	a0,a0,a5
  if(write)
    80006370:	e20d11e3          	bnez	s10,80006192 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006374:	20058713          	addi	a4,a1,512
    80006378:	00471693          	slli	a3,a4,0x4
    8000637c:	0001d717          	auipc	a4,0x1d
    80006380:	c8470713          	addi	a4,a4,-892 # 80023000 <disk>
    80006384:	9736                	add	a4,a4,a3
    80006386:	0a072423          	sw	zero,168(a4)
    8000638a:	b505                	j	800061aa <virtio_disk_rw+0xf4>

000000008000638c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000638c:	1101                	addi	sp,sp,-32
    8000638e:	ec06                	sd	ra,24(sp)
    80006390:	e822                	sd	s0,16(sp)
    80006392:	e426                	sd	s1,8(sp)
    80006394:	e04a                	sd	s2,0(sp)
    80006396:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006398:	0001f517          	auipc	a0,0x1f
    8000639c:	d9050513          	addi	a0,a0,-624 # 80025128 <disk+0x2128>
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063a8:	10001737          	lui	a4,0x10001
    800063ac:	533c                	lw	a5,96(a4)
    800063ae:	8b8d                	andi	a5,a5,3
    800063b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063b6:	0001f797          	auipc	a5,0x1f
    800063ba:	c4a78793          	addi	a5,a5,-950 # 80025000 <disk+0x2000>
    800063be:	6b94                	ld	a3,16(a5)
    800063c0:	0207d703          	lhu	a4,32(a5)
    800063c4:	0026d783          	lhu	a5,2(a3)
    800063c8:	06f70163          	beq	a4,a5,8000642a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063cc:	0001d917          	auipc	s2,0x1d
    800063d0:	c3490913          	addi	s2,s2,-972 # 80023000 <disk>
    800063d4:	0001f497          	auipc	s1,0x1f
    800063d8:	c2c48493          	addi	s1,s1,-980 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063e0:	6898                	ld	a4,16(s1)
    800063e2:	0204d783          	lhu	a5,32(s1)
    800063e6:	8b9d                	andi	a5,a5,7
    800063e8:	078e                	slli	a5,a5,0x3
    800063ea:	97ba                	add	a5,a5,a4
    800063ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063ee:	20078713          	addi	a4,a5,512
    800063f2:	0712                	slli	a4,a4,0x4
    800063f4:	974a                	add	a4,a4,s2
    800063f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063fa:	e731                	bnez	a4,80006446 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063fc:	20078793          	addi	a5,a5,512
    80006400:	0792                	slli	a5,a5,0x4
    80006402:	97ca                	add	a5,a5,s2
    80006404:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006406:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000640a:	ffffc097          	auipc	ra,0xffffc
    8000640e:	f98080e7          	jalr	-104(ra) # 800023a2 <wakeup>

    disk.used_idx += 1;
    80006412:	0204d783          	lhu	a5,32(s1)
    80006416:	2785                	addiw	a5,a5,1
    80006418:	17c2                	slli	a5,a5,0x30
    8000641a:	93c1                	srli	a5,a5,0x30
    8000641c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006420:	6898                	ld	a4,16(s1)
    80006422:	00275703          	lhu	a4,2(a4)
    80006426:	faf71be3          	bne	a4,a5,800063dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000642a:	0001f517          	auipc	a0,0x1f
    8000642e:	cfe50513          	addi	a0,a0,-770 # 80025128 <disk+0x2128>
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
}
    8000643a:	60e2                	ld	ra,24(sp)
    8000643c:	6442                	ld	s0,16(sp)
    8000643e:	64a2                	ld	s1,8(sp)
    80006440:	6902                	ld	s2,0(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret
      panic("virtio_disk_intr status");
    80006446:	00002517          	auipc	a0,0x2
    8000644a:	3da50513          	addi	a0,a0,986 # 80008820 <syscalls+0x3c0>
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

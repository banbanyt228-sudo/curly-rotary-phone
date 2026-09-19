#import <Foundation/Foundation.h>
#import <mach/mach_time.h>
#import <sys/time.h>
#import <dlfcn.h>
#import "fishhook.h"

// Коэффициент ускорения: 1.0 = норма, 2.0 = в 2 раза быстрее, 5.0 = в 5 раз
static double g_speedMultiplier = 2.0;

// Переменные для поддержания непрерывности времени
static uint64_t g_lastRealTime = 0;
static uint64_t g_fakeTime = 0;

static uint64_t (*orig_mach_absolute_time)(void);

static uint64_t hooked_mach_absolute_time(void) {
    uint64_t now = orig_mach_absolute_time();
    
    if (g_lastRealTime == 0) {
        g_lastRealTime = now;
        g_fakeTime = now;
        return now;
    }
    
    uint64_t elapsed = now - g_lastRealTime;
    g_lastRealTime = now;
    
    // Умножаем прошедшее время на наш множитель
    g_fakeTime += (uint64_t)(elapsed * g_speedMultiplier);
    return g_fakeTime;
}

__attribute__((constructor))
static void initSpeedhack(void) {
    orig_mach_absolute_time = (uint64_t (*)(void))dlsym(RTLD_DEFAULT, "mach_absolute_time");
    
    struct rebinding rebindings[] = {
        {"mach_absolute_time", (void *)hooked_mach_absolute_time, (void **)&orig_mach_absolute_time}
    };
    rebind_symbols(rebindings, 1);
}

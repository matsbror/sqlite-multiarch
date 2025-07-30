#ifndef _TIMESTAMPS_H_
#define _TIMESTAMPS_H_

#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define CYCLES 0
#define MILLIS 1
static int mode = MILLIS;
static int initialised = 0;
static FILE *fd = NULL; 
static char *BENCHMARK;
static char *RUNTIME;
static char *HOSTTYPE;

typedef unsigned long long timestamp_t;
typedef unsigned long long timeduration_t; 

void init_timestamps() {
    if (!initialised) {
        const char *filename = getenv("WABENCH_FILE");
        if (filename == NULL) {
            filename = "stdout";
            fd = stdout;
        } else {
            fd = fopen(filename, "a"); // open file for append  
        }

        BENCHMARK = getenv("WABENCHMARK");
        if (BENCHMARK == NULL) {
            BENCHMARK = (char *)"unknown";
        } 

        RUNTIME = getenv("WARUNTIME");
        if (RUNTIME == NULL) {
            RUNTIME = (char *)"unknown";
        } 

        HOSTTYPE = getenv("HOSTTYPE");
        if (HOSTTYPE == NULL) {
            HOSTTYPE = (char *)"unknown";
        } 

        mode = MILLIS;
        initialised = 1;
    }
}

// returns a timestamp in micros since epoch or clock cycles
timestamp_t timestamp() {
    struct timespec ts;

    if (clock_gettime(CLOCK_REALTIME, &ts) < 0) {
        fprintf(stderr, "Could not retrieve correct timestamp");
        exit(-1);
    }

    timestamp_t micro_s = ts.tv_sec * 1000000;
    timestamp_t micro_ns = ts.tv_nsec / 1000;
    return micro_s + micro_ns; 
}

// returns the time since the last time stamp
timeduration_t time_since(timestamp_t ts1){
    timestamp_t ts2 = timestamp();
    return ts2-ts1;
}

void print_timestamp(const char * tag, timestamp_t ts){
    if (!initialised) {
        init_timestamps();
    }
    fprintf(fd, "%s, %s, %s, %s, timestamp, %llu\n", HOSTTYPE, RUNTIME, BENCHMARK, tag, ts);
}

void print_elapsed_time(const char * tag, timeduration_t time){
    if (!initialised) {
        init_timestamps();
    }
    fprintf(fd, "%s, %s, %s, %s, elapsed time, %llu\n", HOSTTYPE, RUNTIME, BENCHMARK, tag, time);
}

#endif
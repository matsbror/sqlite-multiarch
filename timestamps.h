#ifndef _TIMESTAMPS_H_
#define _TIMESTAMPS_H_

#include <time.h>
#include <stdio.h>
#include <stdlib.h>

static int initialised = 0;
static FILE *fd = NULL; 

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
        initialised = 1;
    }
}

// returns a timestamp in milliseconds since epoch
timestamp_t timestamp() {
    struct timespec ts;

    if (clock_gettime(CLOCK_REALTIME, &ts) < 0) {
        fprintf(stderr, "Could not retrieve correct timestamp");
        exit(-1);
    }

    timestamp_t millis = ts.tv_sec * 1000ULL + ts.tv_nsec / 1000000ULL;
    return millis; 
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
    fprintf(fd, "%s, timestamp, %llu\n", tag, ts);
}

void print_elapsed_time(const char * tag, timeduration_t time){
    if (!initialised) {
        init_timestamps();
    }
    fprintf(fd, "%s, elapsed time, %llu\n", tag, time);
}

#endif
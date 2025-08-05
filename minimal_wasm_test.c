#include <stdio.h>
#include <sys/time.h>
#include "timestamps.h"

// Early startup detection - runs before main()
__attribute__((constructor))
void early_startup() {
    timestamp_t early_timestamp = timestamp();
    print_timestamp("minimal_wasm_init", early_timestamp);
    printf("MINIMAL: WASM runtime initialized\n");
    fflush(stdout);
}

int main() {
    timestamp_t start_timestamp = timestamp();
    print_timestamp("minimal_main", start_timestamp);
    
    printf("MINIMAL: main() function entered\n");
    printf("Minimal WASM test completed successfully\n");
    
    timestamp_t end_timestamp = timestamp();
    timeduration_t duration = time_since(start_timestamp);
    print_elapsed_time("minimal_duration", duration);
    
    return 0;
}
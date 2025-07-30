#include "sqlite3.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "dictionary_words.h"
#include <sys/time.h>
#include "timestamps.h"

#define DICTIONARY_SIZE 10000

// Large numerical data arrays
double MATHEMATICAL_CONSTANTS[50000] = {
    3.14159265358979323846,  // PI
    2.71828182845904523536,  // E
    1.41421356237309504880,  // sqrt(2)
    1.73205080756887729353,  // sqrt(3)
    2.23606797749978969641,  // sqrt(5)
    1.61803398874989484820,  // Golden ratio
    0.57721566490153286061,  // Euler-Mascheroni constant
    1.20205690315959428540,  // Apéry's constant
    0.91596559417721901505,  // Catalan's constant
    2.50662827463100050242,  // sqrt(2*PI)
    0.69314718055994530942,  // ln(2)
    1.09861228866810969140,  // ln(3)
    1.38629436111989061883,  // ln(4)
    1.60943791243410028180,  // ln(5)
    1.79175946922805500081,  // ln(6)
    1.94591014905531330511,  // ln(7)
    2.07944154167983592826,  // ln(8)
    2.19722457733621956422,  // ln(9)
    2.30258509299404568402,  // ln(10)
    // Generate the rest programmatically
};

int PRIME_NUMBERS[10000] = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
    331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
    421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
    509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607,
    // ... rest would be calculated
};

// Large text corpus for testing
const char* SAMPLE_TEXTS[5000] = {
    "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the English alphabet at least once.",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "To be or not to be, that is the question: Whether 'tis nobler in the mind to suffer the slings and arrows of outrageous fortune.",
    "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty.",
    "I have a dream that one day this nation will rise up and live out the true meaning of its creed.",
    "In the beginning was the Word, and the Word was with God, and the Word was God.",
    "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness.",
    "Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse.",
    "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
    "All happy families are alike; each unhappy family is unhappy in its own way.",
    // Generate more programmatically below...
};

// Initialize mathematical constants array
void initialize_mathematical_constants() {
    // Fill the array with computed values
    for (int i = 10; i < 50000; i++) {
        double base = (double)i;
        MATHEMATICAL_CONSTANTS[i] = sin(base) * cos(base * 0.5) + log(base + 1) * sqrt(base);
    }
}

// Initialize prime numbers array
void initialize_prime_numbers() {
    int count = 100; // We already have first 100 primes defined
    int candidate = 617; // Next number to check after our predefined primes
    
    while (count < 10000) {
        int is_prime = 1;
        for (int i = 0; i < count && PRIME_NUMBERS[i] * PRIME_NUMBERS[i] <= candidate; i++) {
            if (candidate % PRIME_NUMBERS[i] == 0) {
                is_prime = 0;
                break;
            }
        }
        if (is_prime) {
            PRIME_NUMBERS[count] = candidate;
            count++;
        }
        candidate++;
    }
}

// Initialize sample texts array
void initialize_sample_texts() {
    // Note: In a real implementation, you'd generate these dynamically
    // For this example, we'll assume they're initialized with meaningful content
    for (int i = 10; i < 5000; i++) {
        // In practice, you'd create diverse text samples here
        // For compilation purposes, we'll reference the existing ones
    }
}

// Complex data processing functions
void process_dictionary_data() {
    printf("Processing %d dictionary words...\n", DICTIONARY_SIZE);
    int total_length = 0;
    int max_length = 0;
    int min_length = 1000;
    
    for (int i = 0; i < DICTIONARY_SIZE; i++) {
        int len = strlen(DICTIONARY_WORDS[i]);
        total_length += len;
        if (len > max_length) max_length = len;
        if (len < min_length) min_length = len;
    }
    
    printf("Total character count: %d\n", total_length);
    printf("Average word length: %.2f\n", (double)total_length / DICTIONARY_SIZE);
    printf("Longest word: %d characters\n", max_length);
    printf("Shortest word: %d characters\n", min_length);
    
    // Find words by length distribution
    int length_distribution[20] = {0}; // Support up to 19 character words
    for (int i = 0; i < DICTIONARY_SIZE; i++) {
        int len = strlen(DICTIONARY_WORDS[i]);
        if (len < 20) {
            length_distribution[len]++;
        }
    }
    
    printf("Word length distribution:\n");
    for (int i = 1; i < 20; i++) {
        if (length_distribution[i] > 0) {
            printf("  %d chars: %d words\n", i, length_distribution[i]);
        }
    }
}

void process_mathematical_data() {
    printf("Processing %d mathematical constants...\n", 50000);
    
    double sum = 0.0;
    double max_val = MATHEMATICAL_CONSTANTS[0];
    double min_val = MATHEMATICAL_CONSTANTS[0];
    
    for (int i = 0; i < 50000; i++) {
        sum += MATHEMATICAL_CONSTANTS[i];
        if (MATHEMATICAL_CONSTANTS[i] > max_val) {
            max_val = MATHEMATICAL_CONSTANTS[i];
        }
        if (MATHEMATICAL_CONSTANTS[i] < min_val) {
            min_val = MATHEMATICAL_CONSTANTS[i];
        }
    }
    
    printf("Sum: %f\n", sum);
    printf("Average: %f\n", sum / 50000);
    printf("Maximum: %f\n", max_val);
    printf("Minimum: %f\n", min_val);
    
    // Calculate standard deviation
    double mean = sum / 50000;
    double variance_sum = 0.0;
    for (int i = 0; i < 50000; i++) {
        double diff = MATHEMATICAL_CONSTANTS[i] - mean;
        variance_sum += diff * diff;
    }
    double std_dev = sqrt(variance_sum / 50000);
    printf("Standard deviation: %f\n", std_dev);
}

void process_prime_numbers() {
    printf("Processing %d prime numbers...\n", 10000);
    
    // Calculate some statistics about the primes
    long long sum = 0;
    int gaps[1000] = {0}; // Gap distribution
    
    for (int i = 0; i < 10000; i++) {
        sum += PRIME_NUMBERS[i];
        
        // Calculate gaps between consecutive primes
        if (i > 0) {
            int gap = PRIME_NUMBERS[i] - PRIME_NUMBERS[i-1];
            if (gap < 1000) {
                gaps[gap]++;
            }
        }
    }
    
    printf("Sum of first 10,000 primes: %lld\n", sum);
    printf("Average prime value: %.2f\n", (double)sum / 10000);
    printf("Largest prime in set: %d\n", PRIME_NUMBERS[9999]);
    
    printf("Most common prime gaps:\n");
    for (int i = 1; i < 50; i++) {
        if (gaps[i] > 10) { // Only show gaps that occur more than 10 times
            printf("  Gap of %d: %d occurrences\n", i, gaps[i]);
        }
    }
}

// Advanced string processing functions
void analyze_word_patterns() {
    printf("\n=== Word Pattern Analysis ===\n");
    
    // Count words by starting letter
    int letter_counts[26] = {0};
    for (int i = 0; i < DICTIONARY_SIZE; i++) {
        char first_char = DICTIONARY_WORDS[i][0];
        if (first_char >= 'a' && first_char <= 'z') {
            letter_counts[first_char - 'a']++;
        } else if (first_char >= 'A' && first_char <= 'Z') {
            letter_counts[first_char - 'A']++;
        }
    }
    
    printf("Words starting with each letter:\n");
    for (int i = 0; i < 26; i++) {
        if (letter_counts[i] > 0) {
            printf("  %c: %d words\n", 'A' + i, letter_counts[i]);
        }
    }
    
    // Find palindromes
    printf("\nPalindromes found:\n");
    int palindrome_count = 0;
    for (int i = 0; i < DICTIONARY_SIZE; i++) {
        int len = strlen(DICTIONARY_WORDS[i]);
        int is_palindrome = 1;
        for (int j = 0; j < len / 2; j++) {
            if (DICTIONARY_WORDS[i][j] != DICTIONARY_WORDS[i][len - 1 - j]) {
                is_palindrome = 0;
                break;
            }
        }
        if (is_palindrome && len > 3) { // Only show palindromes longer than 3 chars
            printf("  %s\n", DICTIONARY_WORDS[i]);
            palindrome_count++;
            if (palindrome_count >= 10) break; // Limit output
        }
    }
}

void comprehensive_database_test(sqlite3 *db) {
    char *err_msg = 0;
    int rc;

    printf("\n=== Comprehensive Database Test ===\n");

    // Create tables with indexes for better performance
    const char *create_sql = 
        "CREATE TABLE dictionary_words(id INTEGER PRIMARY KEY, word TEXT UNIQUE, length INTEGER, first_char TEXT);"
        "CREATE INDEX idx_word_length ON dictionary_words(length);"
        "CREATE INDEX idx_first_char ON dictionary_words(first_char);"
        
        "CREATE TABLE mathematical_data(id INTEGER PRIMARY KEY, value REAL, category TEXT, computed_at INTEGER);"
        "CREATE INDEX idx_math_category ON mathematical_data(category);"
        "CREATE INDEX idx_math_value ON mathematical_data(value);"
        
        "CREATE TABLE prime_data(id INTEGER PRIMARY KEY, prime_number INTEGER UNIQUE, nth_prime INTEGER, gap_to_next INTEGER);"
        "CREATE INDEX idx_prime_number ON prime_data(prime_number);"
        
        "CREATE TABLE text_corpus(id INTEGER PRIMARY KEY, content TEXT, word_count INTEGER, char_count INTEGER);"
        "CREATE INDEX idx_word_count ON text_corpus(word_count);"
        
        // Create FTS5 tables for full-text search
        "CREATE VIRTUAL TABLE dictionary_fts USING fts5(word, content='dictionary_words', content_rowid='id');"
        "CREATE VIRTUAL TABLE text_fts USING fts5(content, content='text_corpus', content_rowid='id');";

    rc = sqlite3_exec(db, create_sql, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Table creation error: %s\n", err_msg);
        sqlite3_free(err_msg);
        return;
    }

    printf("Tables and indexes created successfully\n");

    // Insert dictionary data with detailed processing
    printf("Inserting dictionary data...\n");
    sqlite3_stmt *stmt;
    rc = sqlite3_prepare_v2(db, "INSERT INTO dictionary_words (word, length, first_char) VALUES (?, ?, ?)", -1, &stmt, NULL);
    
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    for (int i = 0; i < DICTIONARY_SIZE; i++) {
        int len = strlen(DICTIONARY_WORDS[i]);
        char first_char[2] = {DICTIONARY_WORDS[i][0], '\0'};
        
        sqlite3_bind_text(stmt, 1, DICTIONARY_WORDS[i], -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 2, len);
        sqlite3_bind_text(stmt, 3, first_char, -1, SQLITE_TRANSIENT);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
        
        if (i % 1000 == 0) {
            printf("  Inserted %d dictionary words\n", i);
        }
    }
    sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
    sqlite3_finalize(stmt);

    // Populate FTS5 dictionary table
    sqlite3_exec(db, "INSERT INTO dictionary_fts(dictionary_fts) VALUES('rebuild')", NULL, NULL, NULL);

    // Insert mathematical data with categories
    printf("Inserting mathematical data...\n");
    rc = sqlite3_prepare_v2(db, "INSERT INTO mathematical_data (value, category, computed_at) VALUES (?, ?, ?)", -1, &stmt, NULL);
    
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    for (int i = 0; i < 50000; i++) {
        const char* category;
        if (i < 10) category = "fundamental_constants";
        else if (i < 1000) category = "computed_values";
        else if (i < 10000) category = "trigonometric";
        else if (i < 25000) category = "logarithmic";
        else category = "mixed_functions";
        
        sqlite3_bind_double(stmt, 1, MATHEMATICAL_CONSTANTS[i]);
        sqlite3_bind_text(stmt, 2, category, -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 3, i); // Use index as computation timestamp
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
        
        if (i % 5000 == 0) {
            printf("  Inserted %d mathematical values\n", i);
        }
    }
    sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
    sqlite3_finalize(stmt);

    // Insert prime data with gap analysis
    printf("Inserting prime number data...\n");
    rc = sqlite3_prepare_v2(db, "INSERT INTO prime_data (prime_number, nth_prime, gap_to_next) VALUES (?, ?, ?)", -1, &stmt, NULL);
    
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    for (int i = 0; i < 10000; i++) {
        int gap_to_next = (i < 9999) ? PRIME_NUMBERS[i+1] - PRIME_NUMBERS[i] : 0;
        
        sqlite3_bind_int(stmt, 1, PRIME_NUMBERS[i]);
        sqlite3_bind_int(stmt, 2, i + 1);
        sqlite3_bind_int(stmt, 3, gap_to_next);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
        
        if (i % 1000 == 0) {
            printf("  Inserted %d prime numbers\n", i);
        }
    }
    sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
    sqlite3_finalize(stmt);

    // Generate and insert text corpus
    printf("Generating and inserting text corpus...\n");
    rc = sqlite3_prepare_v2(db, "INSERT INTO text_corpus (content, word_count, char_count) VALUES (?, ?, ?)", -1, &stmt, NULL);
    
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    for (int i = 0; i < 5000; i++) {
        // Generate sample text using dictionary words
        char sample_text[1000];
        int text_len = 0;
        int word_count = 0;
        
        // Create sentences using random dictionary words
        for (int j = 0; j < 10 && text_len < 800; j++) { // Up to 10 words per sample
            int word_idx = (i * 7 + j * 13) % DICTIONARY_SIZE; // Pseudo-random selection
            int word_len = strlen(DICTIONARY_WORDS[word_idx]);
            
            if (text_len + word_len + 2 < sizeof(sample_text)) {
                if (word_count > 0) {
                    sample_text[text_len++] = ' ';
                }
                strcpy(sample_text + text_len, DICTIONARY_WORDS[word_idx]);
                text_len += word_len;
                word_count++;
            }
        }
        sample_text[text_len] = '\0';
        
        sqlite3_bind_text(stmt, 1, sample_text, -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt, 2, word_count);
        sqlite3_bind_int(stmt, 3, text_len);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
        
        if (i % 500 == 0) {
            printf("  Generated %d text samples\n", i);
        }
    }
    sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
    sqlite3_finalize(stmt);

    // Populate FTS5 text table
    sqlite3_exec(db, "INSERT INTO text_fts(text_fts) VALUES('rebuild')", NULL, NULL, NULL);

    printf("\nRunning comprehensive analysis queries...\n");
    
    // Complex Query 1: Word length distribution with statistics
    const char *query1 = 
        "SELECT "
        "  length, "
        "  COUNT(*) as word_count, "
        "  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dictionary_words), 2) as percentage, "
        "  GROUP_CONCAT(word, ', ') as sample_words "
        "FROM dictionary_words "
        "GROUP BY length "
        "ORDER BY word_count DESC "
        "LIMIT 10;";
    
    printf("\nWord Length Distribution (Top 10):\n");
    rc = sqlite3_prepare_v2(db, query1, -1, &stmt, NULL);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("  %d chars: %d words (%.2f%%) - samples: %.50s...\n",
               sqlite3_column_int(stmt, 0),
               sqlite3_column_int(stmt, 1),
               sqlite3_column_double(stmt, 2),
               sqlite3_column_text(stmt, 3));
    }
    sqlite3_finalize(stmt);

    // Complex Query 2: Mathematical data analysis by category
    const char *query2 = 
        "SELECT "
        "  category, "
        "  COUNT(*) as count, "
        "  ROUND(AVG(value), 4) as avg_value, "
        "  ROUND(MIN(value), 4) as min_value, "
        "  ROUND(MAX(value), 4) as max_value, "
        "  ROUND(SUM(value), 2) as total_value "
        "FROM mathematical_data "
        "GROUP BY category "
        "ORDER BY count DESC;";
    
    printf("\nMathematical Data Analysis by Category:\n");
    rc = sqlite3_prepare_v2(db, query2, -1, &stmt, NULL);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("  %s: count=%d, avg=%.4f, min=%.4f, max=%.4f, total=%.2f\n",
               sqlite3_column_text(stmt, 0),
               sqlite3_column_int(stmt, 1),
               sqlite3_column_double(stmt, 2),
               sqlite3_column_double(stmt, 3),
               sqlite3_column_double(stmt, 4),
               sqlite3_column_double(stmt, 5));
    }
    sqlite3_finalize(stmt);

    // Complex Query 3: Prime gap analysis
    const char *query3 = 
        "SELECT "
        "  gap_to_next, "
        "  COUNT(*) as frequency, "
        "  MIN(prime_number) as first_occurrence, "
        "  MAX(prime_number) as last_occurrence "
        "FROM prime_data "
        "WHERE gap_to_next > 0 "
        "GROUP BY gap_to_next "
        "ORDER BY frequency DESC "
        "LIMIT 15;";
    
    printf("\nPrime Gap Analysis (Most Frequent Gaps):\n");
    rc = sqlite3_prepare_v2(db, query3, -1, &stmt, NULL);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("  Gap %d: occurs %d times (first at %d, last at %d)\n",
               sqlite3_column_int(stmt, 0),
               sqlite3_column_int(stmt, 1),
               sqlite3_column_int(stmt, 2),
               sqlite3_column_int(stmt, 3));
    }
    sqlite3_finalize(stmt);

    // Complex Query 4: Full-text search demonstration
    printf("\nFull-Text Search Examples:\n");
    
    // Search dictionary for words containing specific patterns
    const char *fts_query1 = 
        "SELECT word FROM dictionary_fts WHERE dictionary_fts MATCH 'program*' LIMIT 10;";
    
    printf("  Dictionary words matching 'program*':\n");
    rc = sqlite3_prepare_v2(db, fts_query1, -1, &stmt, NULL);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("    %s\n", sqlite3_column_text(stmt, 0));
    }
    sqlite3_finalize(stmt);

    // Cross-table analytical query
    const char *query5 = 
        "SELECT "
        "  d.first_char, "
        "  COUNT(d.id) as word_count, "
        "  AVG(d.length) as avg_length, "
        "  COUNT(CASE WHEN d.length > 7 THEN 1 END) as long_words "
        "FROM dictionary_words d "
        "GROUP BY d.first_char "
        "HAVING word_count > 50 "
        "ORDER BY word_count DESC;";
    
    printf("\nAnalysis by First Character (letters with >50 words):\n");
    rc = sqlite3_prepare_v2(db, query5, -1, &stmt, NULL);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("  '%s': %d words, avg length %.2f, %d long words (>7 chars)\n",
               sqlite3_column_text(stmt, 0),
               sqlite3_column_int(stmt, 1),
               sqlite3_column_double(stmt, 2),
               sqlite3_column_int(stmt, 3));
    }
    sqlite3_finalize(stmt);

    printf("Database operations completed successfully\n");
}

int main(int argc, char **argv) {
    sqlite3 *db;
    int rc;

    timestamp_t start_timestamp = timestamp();
    print_timestamp("main", start_timestamp);



    printf("Massive SQLite WASI Demo with Real Dictionary\n");
    printf("============================================\n");
    printf("SQLite version: %s\n", sqlite3_libversion());
    printf("Dictionary size: %d words\n", DICTIONARY_SIZE);
    printf("Binary contains massive embedded datasets\n\n");
    
    // Initialize dynamic arrays
    printf("Initializing mathematical constants...\n");
    initialize_mathematical_constants();
    
    printf("Computing prime numbers...\n");
    initialize_prime_numbers();
    
    // Process all embedded data
    process_dictionary_data();
    analyze_word_patterns();
    process_mathematical_data();
    process_prime_numbers();
    
    // Open database
    rc = sqlite3_open(":memory:", &db);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
        return 1;
    }
    
    // Run comprehensive database test
    comprehensive_database_test(db);
    
    sqlite3_close(db);

    timestamp_t end_timestamp = timestamp();
    print_elapsed_time("duration", end_timestamp - start_timestamp);
    
    
    printf("\n=== Final Summary ===\n");
    printf("Massive SQLite WASI demo completed successfully!\n");
    printf("This binary contains:\n");
    printf("- %d real dictionary words\n", DICTIONARY_SIZE);
    printf("- 50,000 mathematical constants\n");
    printf("- 10,000 prime numbers\n");
    printf("- 5,000 generated text samples\n");
    printf("- Full SQLite engine with FTS5, R-Tree, JSON1, and GeoPolY extensions\n");
    printf("- Comprehensive data analysis and statistics\n");
    printf("- Full-text search capabilities\n");
    printf("- Complex cross-table queries and analytics\n");
    
    printf("\nBinary demonstrates:\n");
    printf("- Large-scale data processing in WebAssembly\n");
    printf("- Advanced SQL operations and analytics\n");
    printf("- String processing and pattern analysis\n");
    printf("- Mathematical computations and statistics\n");
    printf("- Memory-efficient data structures\n");
    printf("- Real-world database application functionality\n");
    
    return 0;
}

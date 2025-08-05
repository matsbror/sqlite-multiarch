#include "sqlite3.h"
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <vector>
#include <string>
#include <memory>
#include <chrono>
#include "dictionary_words.h"
#include <sys/time.h>
#include "timestamps.h"

#define DICTIONARY_SIZE 10000

// Large numerical data arrays using C++ containers
std::vector<double> MATHEMATICAL_CONSTANTS = {
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
    // Generate additional constants programmatically
};

std::vector<int> PRIME_NUMBERS = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
    331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
    421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
    509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607,
    // Additional primes would be calculated
};

// Large text corpus for testing using C++ strings
std::vector<std::string> SAMPLE_TEXTS = {
    "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the English alphabet at least once.",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "SQLite is a C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine.",
    "WebAssembly (abbreviated Wasm) is a binary instruction format for a stack-based virtual machine.",
    "Container technology has revolutionized software deployment and distribution across different architectures.",
    // Additional sample texts...
};

class SQLiteDatabase {
private:
    sqlite3* db;
    
public:
    SQLiteDatabase() : db(nullptr) {}
    
    ~SQLiteDatabase() {
        if (db) {
            sqlite3_close(db);
        }
    }
    
    bool open(const std::string& filename) {
        int rc = sqlite3_open(filename.c_str(), &db);
        if (rc != SQLITE_OK) {
            std::cerr << "Cannot open database: " << sqlite3_errmsg(db) << std::endl;
            return false;
        }
        return true;
    }
    
    bool execute(const std::string& sql) {
        char* errMsg = nullptr;
        int rc = sqlite3_exec(db, sql.c_str(), nullptr, nullptr, &errMsg);
        
        if (rc != SQLITE_OK) {
            std::cerr << "SQL error: " << errMsg << std::endl;
            sqlite3_free(errMsg);
            return false;
        }
        return true;
    }
    
    sqlite3* getHandle() { return db; }
};

void generate_additional_data() {
    // Generate more mathematical constants
    for (int i = MATHEMATICAL_CONSTANTS.size(); i < 50000; ++i) {
        MATHEMATICAL_CONSTANTS.push_back(sin(i) * cos(i) + sqrt(i));
    }
    
    // Generate more prime numbers (simple sieve)
    std::vector<bool> is_prime(100000, true);
    is_prime[0] = is_prime[1] = false;
    
    for (int i = 2; i * i < 100000; ++i) {
        if (is_prime[i]) {
            for (int j = i * i; j < 100000; j += i) {
                is_prime[j] = false;
            }
        }
    }
    
    PRIME_NUMBERS.clear();
    for (int i = 2; i < 100000 && PRIME_NUMBERS.size() < 10000; ++i) {
        if (is_prime[i]) {
            PRIME_NUMBERS.push_back(i);
        }
    }
    
    // Generate more sample texts
    std::vector<std::string> additional_texts = {
        "C++ is a general-purpose programming language created by Bjarne Stroustrup.",
        "Object-oriented programming provides better code organization and reusability.",
        "STL containers like vector, map, and set provide powerful data structures.",
        "Smart pointers help manage memory automatically and prevent leaks.",
        "Template metaprogramming enables compile-time code generation.",
    };
    
    for (const auto& text : additional_texts) {
        SAMPLE_TEXTS.push_back(text);
    }
    
    while (SAMPLE_TEXTS.size() < 5000) {
        for (const auto& base_text : additional_texts) {
            if (SAMPLE_TEXTS.size() >= 5000) break;
            SAMPLE_TEXTS.push_back(base_text + " (variant " + std::to_string(SAMPLE_TEXTS.size()) + ")");
        }
    }
}

void create_and_populate_tables(SQLiteDatabase& database) {
    std::cout << "Creating and populating comprehensive test tables..." << std::endl;
    
    // Create tables with various SQLite features
    std::vector<std::string> create_statements = {
        // Mathematical constants table
        "CREATE TABLE IF NOT EXISTS math_constants ("
        "id INTEGER PRIMARY KEY, "
        "name TEXT, "
        "value REAL, "
        "description TEXT"
        ")",
        
        // Prime numbers table with FTS
        "CREATE TABLE IF NOT EXISTS prime_numbers ("
        "id INTEGER PRIMARY KEY, "
        "number INTEGER UNIQUE, "
        "is_twin_prime BOOLEAN, "
        "gap_to_next INTEGER"
        ")",
        
        // Sample texts with full-text search
        "CREATE VIRTUAL TABLE IF NOT EXISTS sample_texts USING fts5("
        "content, "
        "category"
        ")",
        
        // Dictionary words table
        "CREATE TABLE IF NOT EXISTS dictionary ("
        "id INTEGER PRIMARY KEY, "
        "word TEXT UNIQUE, "
        "length INTEGER, "
        "first_letter TEXT"
        ")",
        
        // Geospatial data using R-Tree
        "CREATE VIRTUAL TABLE IF NOT EXISTS locations USING rtree("
        "id, "
        "min_x, max_x, "
        "min_y, max_y"
        ")",
        
        // JSON data table
        "CREATE TABLE IF NOT EXISTS json_data ("
        "id INTEGER PRIMARY KEY, "
        "data JSON, "
        "extracted_value TEXT GENERATED ALWAYS AS (json_extract(data, '$.key')) STORED"
        ")"
    };
    
    for (const auto& sql : create_statements) {
        if (!database.execute(sql)) {
            std::cerr << "Failed to create table" << std::endl;
            return;
        }
    }
    
    // Populate mathematical constants
    sqlite3_stmt* stmt;
    const char* insert_math = "INSERT OR REPLACE INTO math_constants (name, value, description) VALUES (?, ?, ?)";
    sqlite3_prepare_v2(database.getHandle(), insert_math, -1, &stmt, nullptr);
    
    std::vector<std::tuple<std::string, double, std::string>> constants = {
        {"PI", M_PI, "Ratio of circumference to diameter"},
        {"E", M_E, "Euler's number"},
        {"SQRT_2", M_SQRT2, "Square root of 2"},
        {"GOLDEN_RATIO", 1.618033988749, "Golden ratio"},
        {"EULER_MASCHERONI", 0.5772156649015, "Euler-Mascheroni constant"}
    };
    
    for (const auto& [name, value, desc] : constants) {
        sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_double(stmt, 2, value);
        sqlite3_bind_text(stmt, 3, desc.c_str(), -1, SQLITE_STATIC);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
    }
    sqlite3_finalize(stmt);
    
    // Populate prime numbers
    const char* insert_prime = "INSERT OR REPLACE INTO prime_numbers (number, is_twin_prime, gap_to_next) VALUES (?, ?, ?)";
    sqlite3_prepare_v2(database.getHandle(), insert_prime, -1, &stmt, nullptr);
    
    for (size_t i = 0; i < std::min(PRIME_NUMBERS.size(), size_t(1000)); ++i) {
        int prime = PRIME_NUMBERS[i];
        bool is_twin = (i > 0 && PRIME_NUMBERS[i] - PRIME_NUMBERS[i-1] == 2) ||
                      (i < PRIME_NUMBERS.size()-1 && PRIME_NUMBERS[i+1] - PRIME_NUMBERS[i] == 2);
        int gap = (i < PRIME_NUMBERS.size()-1) ? PRIME_NUMBERS[i+1] - PRIME_NUMBERS[i] : 0;
        
        sqlite3_bind_int(stmt, 1, prime);
        sqlite3_bind_int(stmt, 2, is_twin ? 1 : 0);
        sqlite3_bind_int(stmt, 3, gap);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
    }
    sqlite3_finalize(stmt);
    
    // Populate sample texts
    const char* insert_text = "INSERT OR REPLACE INTO sample_texts (content, category) VALUES (?, ?)";
    sqlite3_prepare_v2(database.getHandle(), insert_text, -1, &stmt, nullptr);
    
    for (size_t i = 0; i < std::min(SAMPLE_TEXTS.size(), size_t(100)); ++i) {
        std::string category = (i % 3 == 0) ? "technical" : (i % 3 == 1) ? "general" : "scientific";
        sqlite3_bind_text(stmt, 1, SAMPLE_TEXTS[i].c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, category.c_str(), -1, SQLITE_STATIC);
        sqlite3_step(stmt);
        sqlite3_reset(stmt);
    }
    sqlite3_finalize(stmt);
    
    std::cout << "Database populated with comprehensive test data." << std::endl;
}

void run_comprehensive_tests(SQLiteDatabase& database) {
    std::cout << "Running comprehensive SQLite feature tests..." << std::endl;
    
    std::vector<std::string> test_queries = {
        // Basic queries
        "SELECT COUNT(*) as total_constants FROM math_constants",
        "SELECT COUNT(*) as total_primes FROM prime_numbers",
        "SELECT AVG(number) as avg_prime FROM prime_numbers WHERE number < 1000",
        
        // FTS queries
        "SELECT content FROM sample_texts WHERE sample_texts MATCH 'sqlite' LIMIT 5",
        "SELECT COUNT(*) FROM sample_texts WHERE sample_texts MATCH 'programming'",
        
        // JSON queries
        "SELECT COUNT(*) FROM json_data WHERE json_extract(data, '$.type') = 'test'",
        
        // Mathematical functions
        "SELECT name, value, ROUND(value * value, 4) as squared FROM math_constants LIMIT 10",
        "SELECT number, number * number as squared FROM prime_numbers WHERE number < 100",
        
        // Aggregation queries
        "SELECT first_letter, COUNT(*) as word_count FROM dictionary GROUP BY first_letter ORDER BY word_count DESC LIMIT 10",
        
        // Complex queries
        "SELECT p1.number, p2.number FROM prime_numbers p1 JOIN prime_numbers p2 ON p2.number = p1.number + 2 WHERE p1.number < 100"
    };
    
    for (const auto& query : test_queries) {
        std::cout << "Executing: " << query.substr(0, 50) << "..." << std::endl;
        
        sqlite3_stmt* stmt;
        int rc = sqlite3_prepare_v2(database.getHandle(), query.c_str(), -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            int step_result = sqlite3_step(stmt);
            if (step_result == SQLITE_ROW) {
                int columns = sqlite3_column_count(stmt);
                for (int i = 0; i < columns; ++i) {
                    const char* value = reinterpret_cast<const char*>(sqlite3_column_text(stmt, i));
                    std::cout << "  " << (value ? value : "NULL");
                    if (i < columns - 1) std::cout << " | ";
                }
                std::cout << std::endl;
            }
        } else {
            std::cout << "  Query failed: " << sqlite3_errmsg(database.getHandle()) << std::endl;
        }
        
        sqlite3_finalize(stmt);
    }
}

int main() {
    std::cout << "=== Comprehensive SQLite C++ Application ===" << std::endl;
    std::cout << "Multi-architecture SQLite testing with extensive features" << std::endl;
    
    // Generate additional test data
    generate_additional_data();
    std::cout << "Generated " << MATHEMATICAL_CONSTANTS.size() << " mathematical constants" << std::endl;
    std::cout << "Generated " << PRIME_NUMBERS.size() << " prime numbers" << std::endl;
    std::cout << "Generated " << SAMPLE_TEXTS.size() << " sample texts" << std::endl;
    
    // Initialize SQLite database
    SQLiteDatabase database;
    
    if (!database.open(":memory:")) {
        return 1;
    }
    
    std::cout << "SQLite version: " << sqlite3_libversion() << std::endl;
    
    // Create and populate tables
    create_and_populate_tables(database);
    
    // Run comprehensive tests
    run_comprehensive_tests(database);
    
    // Performance test
    auto start_time = std::chrono::high_resolution_clock::now();
    
    // Simulate some computational work
    double sum = 0.0;
    for (const auto& constant : MATHEMATICAL_CONSTANTS) {
        sum += sin(constant) * cos(constant);
    }
    
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
    
    std::cout << "Computational work completed in " << duration.count() << " ms" << std::endl;
    std::cout << "Mathematical sum result: " << sum << std::endl;
    
    std::cout << "=== SQLite C++ Application Complete ===" << std::endl;
    
    return 0;
}
#!/usr/bin/env python3

import random

# Common English word patterns and components
prefixes = [
    "un", "re", "in", "dis", "en", "non", "over", "mis", "sub", "pre", "inter", "fore", 
    "de", "anti", "semi", "micro", "mini", "multi", "auto", "co", "counter", "out", 
    "up", "under", "super", "trans", "extra", "ultra", "meta", "proto", "pseudo"
]

middle_parts = [
    "able", "ible", "tion", "sion", "ness", "ment", "ship", "hood", "ward", "wise",
    "like", "some", "full", "less", "most", "ever", "what", "where", "when", "which",
    "work", "play", "make", "take", "give", "come", "know", "think", "look", "want",
    "use", "find", "tell", "ask", "seem", "feel", "try", "leave", "call", "move",
    "live", "believe", "hold", "bring", "happen", "write", "provide", "sit", "stand",
    "lose", "pay", "meet", "include", "continue", "set", "learn", "change", "lead",
    "understand", "watch", "follow", "stop", "create", "speak", "read", "allow", "add",
    "spend", "grow", "open", "walk", "win", "offer", "remember", "love", "consider",
    "appear", "buy", "wait", "serve", "die", "send", "expect", "build", "stay",
    "fall", "cut", "reach", "kill", "remain", "suggest", "raise", "pass", "sell",
    "require", "report", "decide", "pull", "break", "pick", "wear", "paper", "system",
    "program", "question", "social", "economic", "medical", "political", "financial",
    "cultural", "natural", "international", "national", "local", "global", "personal",
    "professional", "educational", "historical", "scientific", "technical", "digital"
]

suffixes = [
    "ing", "ed", "er", "est", "ly", "tion", "sion", "ness", "ment", "ful", "less",
    "able", "ible", "ous", "ive", "ent", "ant", "ary", "ory", "ic", "al", "ial",
    "ure", "age", "ism", "ist", "ite", "ize", "ise", "fy", "en", "ward", "wise",
    "like", "some", "fold", "teen", "ty", "th", "ship", "hood", "dom", "craft"
]

# Base words to modify
base_words = [
    "action", "activity", "area", "book", "business", "case", "child", "company", "country",
    "course", "day", "development", "education", "end", "example", "experience", "fact",
    "family", "government", "group", "growth", "hand", "health", "history", "home",
    "house", "information", "interest", "job", "level", "life", "line", "management",
    "market", "member", "money", "name", "nation", "nature", "news", "number", "office",
    "order", "organization", "part", "party", "people", "person", "place", "plan",
    "point", "policy", "position", "power", "price", "problem", "process", "program",
    "project", "property", "public", "question", "reason", "report", "research", "result",
    "right", "room", "school", "science", "service", "side", "society", "something",
    "space", "special", "state", "story", "student", "study", "system", "technology",
    "term", "theory", "thing", "time", "trade", "training", "travel", "treatment",
    "university", "value", "war", "water", "way", "week", "woman", "word", "work",
    "world", "year", "young", "design", "computer", "network", "software", "internet",
    "website", "application", "database", "security", "mobile", "device", "platform",
    "solution", "innovation", "strategy", "analysis", "communication", "integration",
    "implementation", "optimization", "performance", "efficiency", "productivity",
    "quality", "standard", "framework", "architecture", "infrastructure", "maintenance",
    "support", "documentation", "interface", "protocol", "algorithm", "structure",
    "function", "operation", "procedure", "method", "approach", "technique", "model",
    "pattern", "concept", "principle", "foundation", "basis", "element", "component",
    "feature", "characteristic", "attribute", "property", "parameter", "variable",
    "constant", "resource", "material", "equipment", "tool", "instrument", "machine",
    "engine", "motor", "device", "apparatus", "mechanism", "circuit", "sensor",
    "controller", "processor", "memory", "storage", "display", "screen", "monitor",
    "keyboard", "mouse", "printer", "scanner", "camera", "microphone", "speaker",
    "headphone", "cable", "connector", "adapter", "battery", "charger", "power",
    "energy", "fuel", "electricity", "voltage", "current", "resistance", "frequency",
    "signal", "wave", "radiation", "light", "color", "sound", "music", "audio",
    "video", "image", "picture", "photo", "graphic", "text", "document", "file",
    "folder", "directory", "path", "location", "address", "contact", "phone", "email",
    "message", "letter", "package", "delivery", "shipping", "transport", "vehicle",
    "car", "truck", "bus", "train", "plane", "ship", "boat", "bicycle", "motorcycle"
]

def generate_word():
    """Generate a realistic-looking word"""
    word_type = random.choice(['base', 'prefixed', 'suffixed', 'compound', 'modified'])
    
    if word_type == 'base':
        return random.choice(base_words)
    
    elif word_type == 'prefixed':
        prefix = random.choice(prefixes)
        base = random.choice(base_words)
        return prefix + base
    
    elif word_type == 'suffixed':
        base = random.choice(base_words)
        suffix = random.choice(suffixes)
        return base + suffix
    
    elif word_type == 'compound':
        word1 = random.choice(base_words)
        word2 = random.choice(base_words)
        return word1 + word2
    
    else:  # modified
        base = random.choice(middle_parts)
        if random.choice([True, False]):
            base = random.choice(prefixes) + base
        if random.choice([True, False]):
            base = base + random.choice(suffixes)
        return base

def generate_dictionary(count=10000):
    """Generate a list of unique dictionary words"""
    words = set()
    
    # Add all base words first
    words.update(base_words)
    
    # Generate additional words until we have enough
    while len(words) < count:
        word = generate_word()
        # Filter out very short or very long words
        if 3 <= len(word) <= 20:
            words.add(word)
    
    return sorted(list(words))[:count]

def main():
    print("Generating 10,000 dictionary words...")
    dictionary = generate_dictionary(10000)
    
    # Write to C header file
    with open('dictionary_words.h', 'w') as f:
        f.write('#ifndef DICTIONARY_WORDS_H\n')
        f.write('#define DICTIONARY_WORDS_H\n\n')
        f.write('const char* DICTIONARY_WORDS[10000] = {\n')
        
        for i, word in enumerate(dictionary):
            f.write(f'    "{word}"')
            if i < len(dictionary) - 1:
                f.write(',')
            f.write('\n')
        
        f.write('};\n\n')
        f.write('#endif // DICTIONARY_WORDS_H\n')
    
    print(f"Generated {len(dictionary)} words and saved to dictionary_words.h")
    print("Sample words:", dictionary[:20])

if __name__ == "__main__":
    main()

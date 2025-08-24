// src/lib/search/utils/highlight.ts
export interface HighlightOptions {
  className?: string;
  tag?: string;
  caseSensitive?: boolean;
}

export function highlightText(
  text: string,
  searchTerms: string | string[],
  options: HighlightOptions = {}
): string {
  const {
    className = 'bg-yellow-200 font-medium',
    tag = 'mark',
    caseSensitive = false
  } = options;

  if (!text || !searchTerms) return text;

  const terms = Array.isArray(searchTerms) ? searchTerms : [searchTerms];
  const validTerms = terms.filter(term => term && term.trim().length > 0);

  if (validTerms.length === 0) return text;

  // Escape special regex characters
  const escapeRegex = (str: string) => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  // Create regex pattern for all terms
  const pattern = validTerms
    .map(term => escapeRegex(term.trim()))
    .join('|');

  const flags = caseSensitive ? 'g' : 'gi';
  const regex = new RegExp(`(${pattern})`, flags);

  // Replace matches with highlighted version
  return text.replace(regex, (match) => {
    return `<${tag} class="${className}">${match}</${tag}>`;
  });
}

export function extractSnippet(
  text: string,
  searchTerms: string | string[],
  maxLength: number = 150
): string {
  if (!text) return '';

  const terms = Array.isArray(searchTerms) ? searchTerms : [searchTerms];
  const validTerms = terms.filter(term => term && term.trim().length > 0);

  if (validTerms.length === 0) {
    return text.length > maxLength
      ? text.substring(0, maxLength) + '...'
      : text;
  }

  // Find the position of the first matching term
  const lowerText = text.toLowerCase();
  let firstMatchIndex = -1;
  let matchedTerm = '';

  for (const term of validTerms) {
    const index = lowerText.indexOf(term.toLowerCase());
    if (index !== -1 && (firstMatchIndex === -1 || index < firstMatchIndex)) {
      firstMatchIndex = index;
      matchedTerm = term;
    }
  }

  if (firstMatchIndex === -1) {
    return text.length > maxLength
      ? text.substring(0, maxLength) + '...'
      : text;
  }

  // Calculate snippet boundaries
  const halfLength = Math.floor(maxLength / 2);
  let start = Math.max(0, firstMatchIndex - halfLength);
  let end = Math.min(text.length, firstMatchIndex + matchedTerm.length + halfLength);

  // Adjust to word boundaries
  if (start > 0) {
    const spaceIndex = text.lastIndexOf(' ', start);
    if (spaceIndex > start - 20) {
      start = spaceIndex + 1;
    }
  }

  if (end < text.length) {
    const spaceIndex = text.indexOf(' ', end);
    if (spaceIndex !== -1 && spaceIndex < end + 20) {
      end = spaceIndex;
    }
  }

  let snippet = text.substring(start, end);
  
  // Add ellipsis
  if (start > 0) snippet = '...' + snippet;
  if (end < text.length) snippet = snippet + '...';

  return snippet;
}

// src/lib/search/utils/spellcheck.ts
export class SpellChecker {
  private dictionary: Map<string, string[]>;

  constructor() {
    // Common misspellings in the wishboard context
    this.dictionary = new Map([
      ['developement', ['development']],
      ['programing', ['programming']],
      ['javasript', ['javascript']],
      ['pyton', ['python']],
      ['desing', ['design']],
      ['buisness', ['business']],
      ['managment', ['management']],
      ['photograpy', ['photography']],
      ['exercize', ['exercise']],
      ['reciepe', ['recipe']],
      ['beginer', ['beginner']],
      ['intermidiate', ['intermediate']],
      ['advaced', ['advanced']]
    ]);
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const m = str1.length;
    const n = str2.length;
    const dp: number[][] = Array(m + 1).fill(null).map(() => Array(n + 1).fill(0));

    for (let i = 0; i <= m; i++) dp[i][0] = i;
    for (let j = 0; j <= n; j++) dp[0][j] = j;

    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        if (str1[i - 1] === str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = Math.min(
            dp[i - 1][j] + 1,    // deletion
            dp[i][j - 1] + 1,    // insertion
            dp[i - 1][j - 1] + 1 // substitution
          );
        }
      }
    }

    return dp[m][n];
  }

  /**
   * Get spelling suggestions for a word
   */
  getSuggestions(word: string, maxSuggestions: number = 3): string[] {
    const lowerWord = word.toLowerCase();
    
    // Check dictionary first
    if (this.dictionary.has(lowerWord)) {
      return this.dictionary.get(lowerWord)!;
    }

    // Common words in wishboard context
    const commonWords = [
      'development', 'programming', 'design', 'learning', 'tutorial',
      'beginner', 'intermediate', 'advanced', 'skills', 'career',
      'hobby', 'lifestyle', 'productivity', 'fitness', 'cooking',
      'photography', 'writing', 'music', 'art', 'business'
    ];

    // Find similar words using Levenshtein distance
    const suggestions = commonWords
      .map(w => ({ word: w, distance: this.levenshteinDistance(lowerWord, w) }))
      .filter(item => item.distance <= 2) // Max 2 character difference
      .sort((a, b) => a.distance - b.distance)
      .slice(0, maxSuggestions)
      .map(item => item.word);

    return suggestions;
  }

  /**
   * Check if a query might be misspelled
   */
  checkQuery(query: string): { hasMisspelling: boolean; suggestions: Map<string, string[]> } {
    const words = query.toLowerCase().split(/\s+/);
    const suggestions = new Map<string, string[]>();
    let hasMisspelling = false;

    for (const word of words) {
      const wordSuggestions = this.getSuggestions(word, 1);
      if (wordSuggestions.length > 0 && wordSuggestions[0] !== word) {
        suggestions.set(word, wordSuggestions);
        hasMisspelling = true;
      }
    }

    return { hasMisspelling, suggestions };
  }

  /**
   * Generate "Did you mean?" suggestion
   */
  getDidYouMean(query: string): string | null {
    const { hasMisspelling, suggestions } = this.checkQuery(query);
    
    if (!hasMisspelling) return null;

    const words = query.split(/\s+/);
    const correctedWords = words.map(word => {
      const lowerWord = word.toLowerCase();
      const wordSuggestions = suggestions.get(lowerWord);
      return wordSuggestions && wordSuggestions.length > 0 
        ? wordSuggestions[0] 
        : word;
    });

    return correctedWords.join(' ');
  }
}

// src/lib/search/utils/synonyms.ts
export class SynonymExpander {
  private synonymGroups: Map<string, Set<string>>;

  constructor() {
    // Define synonym groups for common wishboard terms
    this.synonymGroups = new Map();
    
    const groups = [
      ['programming', 'coding', 'development', 'software'],
      ['design', 'ui', 'ux', 'interface', 'graphics'],
      ['learn', 'study', 'master', 'understand'],
      ['beginner', 'newbie', 'starter', 'novice'],
      ['advanced', 'expert', 'professional', 'pro'],
      ['tutorial', 'guide', 'course', 'lesson'],
      ['fitness', 'exercise', 'workout', 'training'],
      ['cooking', 'culinary', 'recipes', 'cuisine'],
      ['photography', 'photo', 'pictures', 'imaging'],
      ['music', 'audio', 'sound', 'musical'],
      ['business', 'entrepreneur', 'startup', 'company'],
      ['productivity', 'efficiency', 'organization', 'time-management']
    ];

    // Build bidirectional synonym map
    groups.forEach(group => {
      group.forEach(word => {
        const synonyms = new Set(group.filter(w => w !== word));
        if (this.synonymGroups.has(word)) {
          const existing = this.synonymGroups.get(word)!;
          synonyms.forEach(s => existing.add(s));
        } else {
          this.synonymGroups.set(word, synonyms);
        }
      });
    });
  }

  /**
   * Expand a query with synonyms
   */
  expandQuery(query: string, maxExpansion: number = 3): string[] {
    const words = query.toLowerCase().split(/\s+/);
    const expansions = new Set<string>([query]);

    words.forEach(word => {
      if (this.synonymGroups.has(word)) {
        const synonyms = Array.from(this.synonymGroups.get(word)!);
        const selected = synonyms.slice(0, maxExpansion);
        
        selected.forEach(synonym => {
          const expanded = query.toLowerCase().replace(word, synonym);
          expansions.add(expanded);
        });
      }
    });

    return Array.from(expansions);
  }

  /**
   * Get synonyms for a single word
   */
  getSynonyms(word: string): string[] {
    const lowerWord = word.toLowerCase();
    return this.synonymGroups.has(lowerWord) 
      ? Array.from(this.synonymGroups.get(lowerWord)!)
      : [];
  }

  /**
   * Check if two words are synonyms
   */
  areSynonyms(word1: string, word2: string): boolean {
    const lower1 = word1.toLowerCase();
    const lower2 = word2.toLowerCase();
    
    if (lower1 === lower2) return true;
    
    const synonyms = this.synonymGroups.get(lower1);
    return synonyms ? synonyms.has(lower2) : false;
  }
}

// src/lib/search/utils/queryParser.ts
export interface ParsedQuery {
  terms: string[];
  phrases: string[];
  excluded: string[];
  filters: Map<string, string>;
  operators: {
    and: string[][];
    or: string[][];
  };
}

export class QueryParser {
  /**
   * Parse an advanced search query
   */
  parse(query: string): ParsedQuery {
    const result: ParsedQuery = {
      terms: [],
      phrases: [],
      excluded: [],
      filters: new Map(),
      operators: {
        and: [],
        or: []
      }
    };

    // Extract quoted phrases
    const phraseRegex = /"([^"]+)"/g;
    let match;
    while ((match = phraseRegex.exec(query)) !== null) {
      result.phrases.push(match[1]);
    }
    query = query.replace(phraseRegex, '');

    // Extract excluded terms (starting with -)
    const excludeRegex = /-(\w+)/g;
    while ((match = excludeRegex.exec(query)) !== null) {
      result.excluded.push(match[1]);
    }
    query = query.replace(excludeRegex, '');

    // Extract filters (field:value)
    const filterRegex = /(\w+):(\w+)/g;
    while ((match = filterRegex.exec(query)) !== null) {
      result.filters.set(match[1], match[2]);
    }
    query = query.replace(filterRegex, '');

    // Extract AND groups
    const andRegex = /\(([^)]+)\)\s+AND\s+\(([^)]+)\)/g;
    while ((match = andRegex.exec(query)) !== null) {
      result.operators.and.push([match[1].trim(), match[2].trim()]);
    }
    query = query.replace(andRegex, '');

    // Extract OR groups
    const orRegex = /\(([^)]+)\)\s+OR\s+\(([^)]+)\)/g;
    while ((match = orRegex.exec(query)) !== null) {
      result.operators.or.push([match[1].trim(), match[2].trim()]);
    }
    query = query.replace(orRegex, '');

    // Remaining terms
    result.terms = query
      .split(/\s+/)
      .filter(term => term.length > 0 && !['AND', 'OR', 'NOT'].includes(term));

    return result;
  }

  /**
   * Build a human-readable query from parsed components
   */
  buildQuery(parsed: ParsedQuery): string {
    const parts: string[] = [];

    // Add phrases
    parsed.phrases.forEach(phrase => {
      parts.push(`"${phrase}"`);
    });

    // Add regular terms
    parts.push(...parsed.terms);

    // Add excluded terms
    parsed.excluded.forEach(term => {
      parts.push(`-${term}`);
    });

    // Add filters
    parsed.filters.forEach((value, key) => {
      parts.push(`${key}:${value}`);
    });

    return parts.join(' ');
  }

  /**
   * Validate query syntax
   */
  validate(query: string): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Check for unmatched quotes
    const quoteCount = (query.match(/"/g) || []).length;
    if (quoteCount % 2 !== 0) {
      errors.push('Unmatched quotation marks');
    }

    // Check for unmatched parentheses
    const openParen = (query.match(/\(/g) || []).length;
    const closeParen = (query.match(/\)/g) || []).length;
    if (openParen !== closeParen) {
      errors.push('Unmatched parentheses');
    }

    // Check for invalid filter syntax
    const filterRegex = /(\w+):[^\s]+/g;
    const validFilters = ['category', 'tag', 'difficulty', 'author', 'time'];
    let match;
    while ((match = filterRegex.exec(query)) !== null) {
      if (!validFilters.includes(match[1])) {
        errors.push(`Invalid filter: ${match[1]}`);
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}
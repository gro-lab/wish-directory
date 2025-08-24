// src/hooks/useSearch.ts
import { useState, useEffect, useCallback, useRef } from 'react';
import { SearchEngine } from '@/lib/search/SearchEngine';
import { Wishboard } from '@/lib/types';
import { useDebounce } from './useDebounce';

interface SearchFilters {
  category?: string;
  tags?: string[];
  difficulty?: string[];
  minTime?: string;
  maxTime?: string;
  author?: string;
  sortBy?: 'relevance' | 'newest' | 'popular' | 'alphabetical';
}

interface UseSearchOptions {
  debounceMs?: number;
  limit?: number;
  autoSearch?: boolean;
}

interface SearchState {
  results: Wishboard[];
  isSearching: boolean;
  error: Error | null;
  totalResults: number;
  suggestions: string[];
  recentSearches: string[];
  popularTags: { tag: string; count: number }[];
  hasSearched: boolean;
}

export const useSearch = (
  initialWishboards: Wishboard[] = [],
  options: UseSearchOptions = {}
) => {
  const {
    debounceMs = 300,
    limit = 20,
    autoSearch = true
  } = options;

  const searchEngineRef = useRef<SearchEngine | null>(null);
  
  const [query, setQuery] = useState('');
  const [filters, setFilters] = useState<SearchFilters>({});
  const [searchState, setSearchState] = useState<SearchState>({
    results: [],
    isSearching: false,
    error: null,
    totalResults: 0,
    suggestions: [],
    recentSearches: [],
    popularTags: [],
    hasSearched: false
  });

  const debouncedQuery = useDebounce(query, debounceMs);

  // Initialize search engine
  useEffect(() => {
    searchEngineRef.current = new SearchEngine(initialWishboards);
    
    // Load recent searches from localStorage
    const stored = localStorage.getItem('recentSearches');
    if (stored) {
      setSearchState(prev => ({
        ...prev,
        recentSearches: JSON.parse(stored)
      }));
    }

    // Get popular tags
    const popularTags = searchEngineRef.current.getPopularTags(10);
    setSearchState(prev => ({ ...prev, popularTags }));

    return () => {
      searchEngineRef.current?.clearIndex();
    };
  }, [initialWishboards]);

  // Perform search
  const performSearch = useCallback(async (searchQuery: string, searchFilters: SearchFilters) => {
    if (!searchEngineRef.current) return;

    setSearchState(prev => ({ ...prev, isSearching: true, error: null }));

    try {
      // Simulate API delay for realistic UX
      await new Promise(resolve => setTimeout(resolve, 200));

      const results = searchEngineRef.current.searchWithFilters(
        searchQuery,
        searchFilters,
        { limit }
      );

      // Sort results
      const sortedResults = searchEngineRef.current.sortResults(
        results,
        searchFilters.sortBy || 'relevance'
      );

      setSearchState(prev => ({
        ...prev,
        results: sortedResults.map(r => r.item),
        totalResults: sortedResults.length,
        isSearching: false,
        hasSearched: true
      }));

      // Add to recent searches if it's a new search
      if (searchQuery.trim() && !searchState.recentSearches.includes(searchQuery)) {
        const newRecentSearches = [searchQuery, ...searchState.recentSearches].slice(0, 10);
        setSearchState(prev => ({ ...prev, recentSearches: newRecentSearches }));
        localStorage.setItem('recentSearches', JSON.stringify(newRecentSearches));
      }
    } catch (error) {
      setSearchState(prev => ({
        ...prev,
        isSearching: false,
        error: error as Error
      }));
    }
  }, [limit, searchState.recentSearches]);

  // Auto search on query/filter change
  useEffect(() => {
    if (autoSearch && (debouncedQuery || Object.keys(filters).length > 0)) {
      performSearch(debouncedQuery, filters);
    } else if (!debouncedQuery && Object.keys(filters).length === 0) {
      // Reset to all wishboards if no search or filters
      setSearchState(prev => ({
        ...prev,
        results: initialWishboards,
        totalResults: initialWishboards.length,
        hasSearched: false
      }));
    }
  }, [debouncedQuery, filters, autoSearch, performSearch, initialWishboards]);

  // Get suggestions
  useEffect(() => {
    if (searchEngineRef.current && query.length > 1) {
      const suggestions = searchEngineRef.current.getSuggestions(query, 5);
      setSearchState(prev => ({ ...prev, suggestions }));
    } else {
      setSearchState(prev => ({ ...prev, suggestions: [] }));
    }
  }, [query]);

  // Public API
  const search = useCallback((searchQuery?: string) => {
    const finalQuery = searchQuery ?? query;
    performSearch(finalQuery, filters);
  }, [query, filters, performSearch]);

  const updateFilters = useCallback((newFilters: Partial<SearchFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  }, []);

  const clearFilters = useCallback(() => {
    setFilters({});
  }, []);

  const clearSearch = useCallback(() => {
    setQuery('');
    setFilters({});
    setSearchState(prev => ({
      ...prev,
      results: initialWishboards,
      totalResults: initialWishboards.length,
      hasSearched: false
    }));
  }, [initialWishboards]);

  const removeRecentSearch = useCallback((searchToRemove: string) => {
    const newRecentSearches = searchState.recentSearches.filter(s => s !== searchToRemove);
    setSearchState(prev => ({ ...prev, recentSearches: newRecentSearches }));
    localStorage.setItem('recentSearches', JSON.stringify(newRecentSearches));
  }, [searchState.recentSearches]);

  const clearRecentSearches = useCallback(() => {
    setSearchState(prev => ({ ...prev, recentSearches: [] }));
    localStorage.removeItem('recentSearches');
  }, []);

  const getTrending = useCallback((timeWindow: 'day' | 'week' | 'month' = 'week', trendingLimit: number = 10) => {
    if (!searchEngineRef.current) return [];
    return searchEngineRef.current.getTrendingWishboards(timeWindow, trendingLimit);
  }, []);

  return {
    // State
    query,
    filters,
    results: searchState.results,
    isSearching: searchState.isSearching,
    error: searchState.error,
    totalResults: searchState.totalResults,
    suggestions: searchState.suggestions,
    recentSearches: searchState.recentSearches,
    popularTags: searchState.popularTags,
    hasSearched: searchState.hasSearched,
    
    // Actions
    setQuery,
    search,
    updateFilters,
    clearFilters,
    clearSearch,
    removeRecentSearch,
    clearRecentSearches,
    getTrending
  };
};

// src/hooks/useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// src/hooks/useFilters.ts
import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

interface FilterState {
  category: string;
  tags: string[];
  difficulty: string[];
  timeRange: { min: string; max: string };
  sortBy: 'relevance' | 'newest' | 'popular' | 'alphabetical';
}

const defaultFilters: FilterState = {
  category: '',
  tags: [],
  difficulty: [],
  timeRange: { min: '', max: '' },
  sortBy: 'relevance'
};

export const useFilters = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [filters, setFilters] = useState<FilterState>(defaultFilters);
  const [filterPresets, setFilterPresets] = useState<{ name: string; filters: FilterState }[]>([]);

  // Initialize filters from URL params
  useEffect(() => {
    const params = new URLSearchParams(searchParams.toString());
    const urlFilters: Partial<FilterState> = {};

    const category = params.get('category');
    if (category) urlFilters.category = category;

    const tags = params.get('tags');
    if (tags) urlFilters.tags = tags.split(',');

    const difficulty = params.get('difficulty');
    if (difficulty) urlFilters.difficulty = difficulty.split(',');

    const sortBy = params.get('sort');
    if (sortBy && ['relevance', 'newest', 'popular', 'alphabetical'].includes(sortBy)) {
      urlFilters.sortBy = sortBy as FilterState['sortBy'];
    }

    setFilters(prev => ({ ...prev, ...urlFilters }));
  }, [searchParams]);

  // Sync filters to URL
  const syncToUrl = useCallback((newFilters: FilterState) => {
    const params = new URLSearchParams();
    
    if (newFilters.category) params.set('category', newFilters.category);
    if (newFilters.tags.length) params.set('tags', newFilters.tags.join(','));
    if (newFilters.difficulty.length) params.set('difficulty', newFilters.difficulty.join(','));
    if (newFilters.sortBy !== 'relevance') params.set('sort', newFilters.sortBy);
    
    const queryString = params.toString();
    const newUrl = queryString ? `?${queryString}` : window.location.pathname;
    
    router.push(newUrl, { scroll: false });
  }, [router]);

  // Update single filter
  const updateFilter = useCallback(<K extends keyof FilterState>(
    key: K,
    value: FilterState[K]
  ) => {
    setFilters(prev => {
      const newFilters = { ...prev, [key]: value };
      syncToUrl(newFilters);
      return newFilters;
    });
  }, [syncToUrl]);

  // Update multiple filters
  const updateFilters = useCallback((updates: Partial<FilterState>) => {
    setFilters(prev => {
      const newFilters = { ...prev, ...updates };
      syncToUrl(newFilters);
      return newFilters;
    });
  }, [syncToUrl]);

  // Toggle array filter item
  const toggleArrayFilter = useCallback(<K extends keyof FilterState>(
    key: K,
    value: string
  ) => {
    setFilters(prev => {
      const currentArray = prev[key] as string[];
      const newArray = currentArray.includes(value)
        ? currentArray.filter(item => item !== value)
        : [...currentArray, value];
      
      const newFilters = { ...prev, [key]: newArray };
      syncToUrl(newFilters);
      return newFilters;
    });
  }, [syncToUrl]);

  // Clear all filters
  const clearFilters = useCallback(() => {
    setFilters(defaultFilters);
    router.push(window.location.pathname, { scroll: false });
  }, [router]);

  // Save filter preset
  const savePreset = useCallback((name: string) => {
    const newPreset = { name, filters: { ...filters } };
    const updatedPresets = [...filterPresets, newPreset];
    setFilterPresets(updatedPresets);
    localStorage.setItem('filterPresets', JSON.stringify(updatedPresets));
  }, [filters, filterPresets]);

  // Load filter preset
  const loadPreset = useCallback((presetName: string) => {
    const preset = filterPresets.find(p => p.name === presetName);
    if (preset) {
      updateFilters(preset.filters);
    }
  }, [filterPresets, updateFilters]);

  // Load presets from localStorage
  useEffect(() => {
    const stored = localStorage.getItem('filterPresets');
    if (stored) {
      setFilterPresets(JSON.parse(stored));
    }
  }, []);

  // Calculate active filter count
  const activeFilterCount = 
    (filters.category ? 1 : 0) +
    filters.tags.length +
    filters.difficulty.length +
    (filters.timeRange.min || filters.timeRange.max ? 1 : 0);

  return {
    filters,
    activeFilterCount,
    filterPresets,
    updateFilter,
    updateFilters,
    toggleArrayFilter,
    clearFilters,
    savePreset,
    loadPreset
  };
};

// src/hooks/useSearchSuggestions.ts
import { useState, useEffect, useCallback } from 'react';

interface Suggestion {
  text: string;
  type: 'query' | 'tag' | 'category' | 'author';
  metadata?: any;
}

export const useSearchSuggestions = (query: string, limit: number = 5) => {
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [popularSuggestions, setPopularSuggestions] = useState<Suggestion[]>([]);

  // Fetch suggestions based on query
  const fetchSuggestions = useCallback(async (searchQuery: string) => {
    if (searchQuery.length < 2) {
      setSuggestions([]);
      return;
    }

    setIsLoading(true);
    
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Mock suggestions based on query
      const mockSuggestions: Suggestion[] = [
        { text: `${searchQuery} tutorial`, type: 'query' },
        { text: `${searchQuery} for beginners`, type: 'query' },
        { text: `Learn ${searchQuery}`, type: 'query' },
        { text: searchQuery.toLowerCase(), type: 'tag' },
        { text: 'Skills', type: 'category' }
      ].filter(s => 
        s.text.toLowerCase().includes(searchQuery.toLowerCase())
      ).slice(0, limit);

      setSuggestions(mockSuggestions);
    } catch (error) {
      console.error('Failed to fetch suggestions:', error);
      setSuggestions([]);
    } finally {
      setIsLoading(false);
    }
  }, [limit]);

  // Fetch popular suggestions on mount
  useEffect(() => {
    const fetchPopular = async () => {
      // Mock popular suggestions
      setPopularSuggestions([
        { text: 'iOS Development', type: 'query' },
        { text: 'Web Design', type: 'query' },
        { text: 'Digital Marketing', type: 'query' },
        { text: 'Photography', type: 'tag' },
        { text: 'Productivity', type: 'tag' }
      ]);
    };

    fetchPopular();
  }, []);

  // Debounced fetch
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchSuggestions(query);
    }, 200);

    return () => clearTimeout(timer);
  }, [query, fetchSuggestions]);

  return {
    suggestions,
    popularSuggestions,
    isLoading
  };
};
// src/components/search/SearchInterface.tsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Search, X, TrendingUp, Clock, Filter, ChevronDown } from 'lucide-react';

interface SearchSuggestion {
  text: string;
  type: 'query' | 'tag' | 'category' | 'recent';
  icon?: React.ReactNode;
}

interface FilterState {
  category: string;
  tags: string[];
  difficulty: string[];
  timeRange: { min: string; max: string };
  sortBy: 'relevance' | 'newest' | 'popular' | 'alphabetical';
}

const SearchInterface: React.FC = () => {
  const [query, setQuery] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestions, setSuggestions] = useState<SearchSuggestion[]>([]);
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [showFilters, setShowFilters] = useState(false);
  const [activeFilters, setActiveFilters] = useState<FilterState>({
    category: '',
    tags: [],
    difficulty: [],
    timeRange: { min: '', max: '' },
    sortBy: 'relevance'
  });
  const [isSearching, setIsSearching] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Mock data for demo
  const mockSuggestions: SearchSuggestion[] = [
    { text: 'iOS Development', type: 'query', icon: <Search className="w-4 h-4" /> },
    { text: 'SwiftUI', type: 'tag', icon: <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Tag</span> },
    { text: 'Learn React Native', type: 'query', icon: <Search className="w-4 h-4" /> },
    { text: 'programming', type: 'tag', icon: <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Tag</span> },
    { text: 'Skills', type: 'category', icon: <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">Category</span> }
  ];

  const categories = ['All', 'Skills', 'Hobbies', 'Lifestyle', 'Career'];
  const difficultyLevels = ['Beginner', 'Intermediate', 'Advanced'];
  const sortOptions = [
    { value: 'relevance', label: 'Most Relevant' },
    { value: 'newest', label: 'Newest First' },
    { value: 'popular', label: 'Most Popular' },
    { value: 'alphabetical', label: 'A-Z' }
  ];

  const popularTags = [
    { tag: 'programming', count: 156 },
    { tag: 'design', count: 124 },
    { tag: 'productivity', count: 98 },
    { tag: 'fitness', count: 87 },
    { tag: 'cooking', count: 76 },
    { tag: 'music', count: 65 },
    { tag: 'photography', count: 54 },
    { tag: 'writing', count: 43 }
  ];

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (query.length > 1) {
        setIsSearching(true);
        // Simulate API call
        setTimeout(() => {
          setSuggestions(mockSuggestions.filter(s => 
            s.text.toLowerCase().includes(query.toLowerCase())
          ));
          setIsSearching(false);
        }, 300);
      } else {
        setSuggestions([]);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

  // Handle click outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setShowSuggestions(false);
        setShowFilters(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSearch = (searchQuery: string) => {
    if (searchQuery.trim()) {
      // Add to recent searches
      setRecentSearches(prev => [searchQuery, ...prev.filter(s => s !== searchQuery)].slice(0, 5));
      // Perform search
      console.log('Searching for:', searchQuery, 'with filters:', activeFilters);
      setShowSuggestions(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch(query);
    }
  };

  const toggleTag = (tag: string) => {
    setActiveFilters(prev => ({
      ...prev,
      tags: prev.tags.includes(tag)
        ? prev.tags.filter(t => t !== tag)
        : [...prev.tags, tag]
    }));
  };

  const clearFilters = () => {
    setActiveFilters({
      category: '',
      tags: [],
      difficulty: [],
      timeRange: { min: '', max: '' },
      sortBy: 'relevance'
    });
  };

  const activeFilterCount = 
    (activeFilters.category ? 1 : 0) +
    activeFilters.tags.length +
    activeFilters.difficulty.length +
    (activeFilters.timeRange.min || activeFilters.timeRange.max ? 1 : 0);

  return (
    <div className="w-full max-w-4xl mx-auto p-4" ref={searchRef}>
      {/* Main Search Bar */}
      <div className="relative">
        <div className="flex gap-2">
          <div className="flex-1 relative">
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onFocus={() => setShowSuggestions(true)}
              onKeyDown={handleKeyDown}
              placeholder="Search wishboards, topics, or creators..."
              className="w-full px-4 py-3 pl-12 pr-10 text-gray-900 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
            />
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            )}
            {isSearching && (
              <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-500"></div>
              </div>
            )}
          </div>
          
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`px-4 py-3 bg-white border rounded-xl flex items-center gap-2 transition-all ${
              showFilters ? 'border-indigo-500 text-indigo-600' : 'border-gray-200 text-gray-700 hover:border-gray-300'
            }`}
          >
            <Filter className="w-5 h-5" />
            <span className="hidden sm:inline">Filters</span>
            {activeFilterCount > 0 && (
              <span className="bg-indigo-500 text-white text-xs px-1.5 py-0.5 rounded-full">
                {activeFilterCount}
              </span>
            )}
          </button>
        </div>

        {/* Search Suggestions Dropdown */}
        {showSuggestions && (query.length > 0 || recentSearches.length > 0) && (
          <div className="absolute z-20 w-full mt-2 bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
            {query.length > 0 && suggestions.length > 0 && (
              <div className="p-2">
                <div className="text-xs text-gray-500 px-3 py-2 font-medium">Suggestions</div>
                {suggestions.map((suggestion, index) => (
                  <button
                    key={index}
                    onClick={() => {
                      setQuery(suggestion.text);
                      handleSearch(suggestion.text);
                    }}
                    className="w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-50 rounded-lg transition-colors text-left"
                  >
                    {suggestion.icon}
                    <span className="flex-1 text-gray-700">{suggestion.text}</span>
                  </button>
                ))}
              </div>
            )}
            
            {recentSearches.length > 0 && (
              <div className="p-2 border-t border-gray-100">
                <div className="text-xs text-gray-500 px-3 py-2 font-medium flex items-center gap-2">
                  <Clock className="w-3 h-3" />
                  Recent Searches
                </div>
                {recentSearches.map((search, index) => (
                  <button
                    key={index}
                    onClick={() => {
                      setQuery(search);
                      handleSearch(search);
                    }}
                    className="w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-50 rounded-lg transition-colors text-left"
                  >
                    <Clock className="w-4 h-4 text-gray-400" />
                    <span className="flex-1 text-gray-600">{search}</span>
                  </button>
                ))}
              </div>
            )}

            <div className="p-2 border-t border-gray-100">
              <button className="w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-50 rounded-lg transition-colors text-left">
                <TrendingUp className="w-4 h-4 text-indigo-500" />
                <span className="text-indigo-600 font-medium">View trending searches</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Filters Panel */}
      {showFilters && (
        <div className="mt-4 p-4 bg-white rounded-xl border border-gray-200 shadow-sm animate-in slide-in-from-top duration-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900">Filters</h3>
            {activeFilterCount > 0 && (
              <button
                onClick={clearFilters}
                className="text-sm text-indigo-600 hover:text-indigo-700 transition-colors"
              >
                Clear all
              </button>
            )}
          </div>

          {/* Category Filter */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
            <div className="flex flex-wrap gap-2">
              {categories.map(cat => (
                <button
                  key={cat}
                  onClick={() => setActiveFilters(prev => ({ 
                    ...prev, 
                    category: prev.category === cat ? '' : cat 
                  }))}
                  className={`px-3 py-1.5 rounded-lg border transition-all ${
                    activeFilters.category === cat
                      ? 'bg-indigo-500 text-white border-indigo-500'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-gray-400'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Popular Tags */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">Popular Tags</label>
            <div className="flex flex-wrap gap-2">
              {popularTags.map(({ tag, count }) => (
                <button
                  key={tag}
                  onClick={() => toggleTag(tag)}
                  className={`px-3 py-1.5 rounded-lg border transition-all flex items-center gap-1 ${
                    activeFilters.tags.includes(tag)
                      ? 'bg-indigo-500 text-white border-indigo-500'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-gray-400'
                  }`}
                >
                  {tag}
                  <span className={`text-xs ${
                    activeFilters.tags.includes(tag) ? 'text-indigo-100' : 'text-gray-500'
                  }`}>
                    {count}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Difficulty Filter */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">Difficulty</label>
            <div className="flex gap-2">
              {difficultyLevels.map(level => (
                <label key={level} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={activeFilters.difficulty.includes(level)}
                    onChange={() => {
                      setActiveFilters(prev => ({
                        ...prev,
                        difficulty: prev.difficulty.includes(level)
                          ? prev.difficulty.filter(d => d !== level)
                          : [...prev.difficulty, level]
                      }));
                    }}
                    className="mr-2 rounded text-indigo-500 focus:ring-indigo-500"
                  />
                  <span className="text-sm text-gray-700">{level}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Sort By */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Sort By</label>
            <select
              value={activeFilters.sortBy}
              onChange={(e) => setActiveFilters(prev => ({ 
                ...prev, 
                sortBy: e.target.value as FilterState['sortBy']
              }))}
              className="w-full sm:w-auto px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {sortOptions.map(option => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>

          {/* Apply Filters Button */}
          <div className="mt-4 pt-4 border-t border-gray-200">
            <button
              onClick={() => handleSearch(query)}
              className="w-full sm:w-auto px-6 py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition-colors"
            >
              Apply Filters
            </button>
          </div>
        </div>
      )}

      {/* Active Filters Display */}
      {activeFilterCount > 0 && !showFilters && (
        <div className="mt-3 flex flex-wrap gap-2 items-center">
          <span className="text-sm text-gray-500">Active filters:</span>
          {activeFilters.category && (
            <span className="inline-flex items-center gap-1 px-2 py-1 bg-indigo-100 text-indigo-700 rounded-lg text-sm">
              {activeFilters.category}
              <button onClick={() => setActiveFilters(prev => ({ ...prev, category: '' }))}>
                <X className="w-3 h-3" />
              </button>
            </span>
          )}
          {activeFilters.tags.map(tag => (
            <span key={tag} className="inline-flex items-center gap-1 px-2 py-1 bg-indigo-100 text-indigo-700 rounded-lg text-sm">
              {tag}
              <button onClick={() => toggleTag(tag)}>
                <X className="w-3 h-3" />
              </button>
            </span>
          ))}
          {activeFilters.difficulty.map(level => (
            <span key={level} className="inline-flex items-center gap-1 px-2 py-1 bg-purple-100 text-purple-700 rounded-lg text-sm">
              {level}
              <button onClick={() => setActiveFilters(prev => ({
                ...prev,
                difficulty: prev.difficulty.filter(d => d !== level)
              }))}>
                <X className="w-3 h-3" />
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

export default SearchInterface;
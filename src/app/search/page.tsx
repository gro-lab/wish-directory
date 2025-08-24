// src/app/search/page.tsx
import React, { useState, useEffect } from 'react';
import { useSearch } from '@/hooks/useSearch';
import { sampleWishboards } from '@/data';
import SearchInterface from '@/components/search/SearchInterface';
import SearchResults from '@/components/search/SearchResults';
import CategoryBrowser from '@/components/browse/CategoryBrowser';
import FilterSidebar from '@/components/filters/FilterSidebar';
import { 
  Search, 
  Filter, 
  TrendingUp, 
  Grid3X3,
  LayoutGrid,
  List,
  ChevronLeft
} from 'lucide-react';

const SearchPage: React.FC = () => {
  const [view, setView] = useState<'search' | 'browse' | 'trending'>('search');
  const [showFilters, setShowFilters] = useState(false);
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

  const {
    query,
    filters,
    results,
    isSearching,
    error,
    totalResults,
    suggestions,
    recentSearches,
    popularTags,
    hasSearched,
    setQuery,
    search,
    updateFilters,
    clearFilters,
    clearSearch,
    getTrending
  } = useSearch(sampleWishboards);

  // Get available filter options from data
  const availableFilters = {
    categories: Array.from(new Set(sampleWishboards.map((wb: any) => wb.category)))
      .map(cat => ({
        name: cat,
        count: sampleWishboards.filter((wb: any) => wb.category === cat).length
      })),
    tags: Array.from(new Set(sampleWishboards.flatMap((wb: any) => wb.tags)))
      .map(tag => ({
        name: tag,
        count: sampleWishboards.filter((wb: any) => wb.tags.includes(tag)).length
      }))
      .sort((a, b) => b.count - a.count),
    difficulties: ['Beginner', 'Intermediate', 'Advanced'],
    authors: Array.from(new Set(sampleWishboards.map((wb: any) => wb.author.name)))
  };

  const trendingWishboards = getTrending('week', 5);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header Navigation */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <h1 className="text-xl font-semibold text-gray-900">
                Discover Wishboards
              </h1>
              <div className="hidden md:flex items-center gap-2">
                <button
                  onClick={() => setView('search')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    view === 'search'
                      ? 'bg-indigo-100 text-indigo-700'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <Search className="w-4 h-4 inline mr-1" />
                  Search
                </button>
                <button
                  onClick={() => setView('browse')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    view === 'browse'
                      ? 'bg-indigo-100 text-indigo-700'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <Grid3X3 className="w-4 h-4 inline mr-1" />
                  Browse
                </button>
                <button
                  onClick={() => setView('trending')}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    view === 'trending'
                      ? 'bg-indigo-100 text-indigo-700'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <TrendingUp className="w-4 h-4 inline mr-1" />
                  Trending
                </button>
              </div>
            </div>

            {view === 'search' && (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowFilters(!showFilters)}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors md:hidden ${
                    showFilters
                      ? 'bg-indigo-100 text-indigo-700 border-indigo-300'
                      : 'text-gray-600 border-gray-300 hover:border-gray-400'
                  }`}
                >
                  <Filter className="w-4 h-4" />
                </button>
                <div className="flex items-center gap-1 border border-gray-300 rounded-lg p-0.5">
                  <button
                    onClick={() => setLayoutMode('grid')}
                    className={`p-1.5 rounded transition-colors ${
                      layoutMode === 'grid'
                        ? 'bg-gray-900 text-white'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    <LayoutGrid className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => setLayoutMode('list')}
                    className={`p-1.5 rounded transition-colors ${
                      layoutMode === 'list'
                        ? 'bg-gray-900 text-white'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    <List className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {view === 'search' && (
          <div className="flex gap-6">
            {/* Desktop Filter Sidebar */}
            <div className="hidden lg:block w-80 flex-shrink-0">
              <FilterSidebar
                isOpen={true}
                onClose={() => {}}
                filters={filters}
                onFilterChange={updateFilters}
                availableFilters={availableFilters}
              />
            </div>

            {/* Mobile Filter Sidebar */}
            <div className="lg:hidden">
              <FilterSidebar
                isOpen={showFilters}
                onClose={() => setShowFilters(false)}
                filters={filters}
                onFilterChange={updateFilters}
                availableFilters={availableFilters}
              />
            </div>

            {/* Search Results Area */}
            <div className="flex-1">
              <SearchInterface />
              
              {error && (
                <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-red-800">Error: {error.message}</p>
                </div>
              )}

              {isSearching ? (
                <div className="mt-8 space-y-4">
                  {[1, 2, 3].map(i => (
                    <div key={i} className="bg-white rounded-lg border border-gray-200 p-6">
                      <div className="animate-pulse">
                        <div className="h-6 bg-gray-200 rounded w-3/4 mb-3"></div>
                        <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
                        <div className="h-4 bg-gray-200 rounded w-2/3"></div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : hasSearched || query || Object.keys(filters).some(key => {
                const value = filters[key as keyof typeof filters];
                return Array.isArray(value) ? value.length > 0 : !!value;
              }) ? (
                <div className="mt-6">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-semibold text-gray-900">
                      {totalResults} Results {query && `for "${query}"`}
                    </h2>
                  </div>
                  
                  {layoutMode === 'grid' ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {results.map(wishboard => (
                        <WishboardCard key={wishboard.id} wishboard={wishboard} />
                      ))}
                    </div>
                  ) : (
                    <SearchResults />
                  )}
                </div>
              ) : (
                <div className="mt-8">
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">
                    Popular Wishboards
                  </h2>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {sampleWishboards.slice(0, 6).map(wishboard => (
                      <WishboardCard key={wishboard.id} wishboard={wishboard} />
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {view === 'browse' && <CategoryBrowser />}

        {view === 'trending' && (
          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-6">
              Trending This Week
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {trendingWishboards.map(wishboard => (
                <WishboardCard key={wishboard.id} wishboard={wishboard} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Wishboard Card Component
interface WishboardCardProps {
  wishboard: any; // Using any for now, should be Wishboard type
}

const WishboardCard: React.FC<WishboardCardProps> = ({ wishboard }) => {
  return (
    <div className="bg-white rounded-lg border border-gray-200 hover:border-indigo-300 hover:shadow-lg transition-all duration-200 overflow-hidden group">
      <div className="p-5">
        <div className="flex items-start justify-between mb-3">
          <h3 className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">
            {wishboard.title}
          </h3>
          <span className={`px-2 py-1 rounded text-xs font-medium ${
            wishboard.difficulty === 'Beginner' 
              ? 'bg-green-100 text-green-700'
              : wishboard.difficulty === 'Intermediate'
              ? 'bg-yellow-100 text-yellow-700'
              : 'bg-red-100 text-red-700'
          }`}>
            {wishboard.difficulty}
          </span>
        </div>
        
        <p className="text-sm text-gray-600 mb-3 line-clamp-2">
          {wishboard.description}
        </p>

        <div className="flex items-center gap-2 mb-3">
          <span className="text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded">
            {wishboard.category}
          </span>
          <span className="text-xs text-gray-500">•</span>
          <span className="text-xs text-gray-500">{wishboard.estimatedTime}</span>
        </div>

        <div className="flex items-center justify-between">
          <p className="text-xs text-gray-500">
            by {wishboard.author.name}
          </p>
          <div className="flex items-center gap-3 text-xs text-gray-500">
            <span>{wishboard.stats.views} views</span>
            <span>{wishboard.stats.saves} saves</span>
          </div>
        </div>

        <div className="flex flex-wrap gap-1 mt-3">
          {wishboard.tags.slice(0, 3).map((tag: string) => (
            <span
              key={tag}
              className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg"
            >
              {tag}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

export default SearchPage;
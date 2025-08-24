// src/components/search/SearchResults.tsx
import React, { useState } from 'react';
import { 
  Search, 
  Filter, 
  ChevronLeft, 
  ChevronRight, 
  Eye, 
  Bookmark, 
  Clock, 
  Award,
  TrendingUp,
  AlertCircle,
  Sparkles,
  ArrowUpDown
} from 'lucide-react';

interface SearchResult {
  id: string;
  title: string;
  description: string;
  author: {
    name: string;
    avatar: string;
  };
  category: string;
  tags: string[];
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  timeEstimate: string;
  stats: {
    views: number;
    saves: number;
    rating: number;
  };
  createdAt: string;
  matchScore?: number;
  highlights?: {
    title?: string;
    description?: string;
    tags?: string[];
  };
}

const SearchResults: React.FC = () => {
  const [currentPage, setCurrentPage] = useState(1);
  const [resultsPerPage] = useState(10);
  const [sortBy, setSortBy] = useState<'relevance' | 'newest' | 'popular'>('relevance');

  // Mock search query for highlighting
  const searchQuery = 'iOS development';
  const searchTerms = searchQuery.toLowerCase().split(' ');

  // Mock search results
  const mockResults: SearchResult[] = [
    {
      id: '1',
      title: 'Learn iOS App Development',
      description: 'Complete guide to building iOS applications with Swift and SwiftUI. Perfect for beginners who want to start their iOS development journey.',
      author: { name: 'Alex Chen', avatar: '👨‍💻' },
      category: 'Skills',
      tags: ['ios', 'swift', 'mobile-development', 'programming'],
      difficulty: 'Intermediate',
      timeEstimate: '3-6 months',
      stats: { views: 15234, saves: 892, rating: 4.8 },
      createdAt: '2024-01-15',
      matchScore: 0.95,
      highlights: {
        title: 'Learn <mark>iOS</mark> App <mark>Development</mark>',
        description: 'Complete guide to building <mark>iOS</mark> applications with Swift and SwiftUI.',
        tags: ['<mark>ios</mark>', 'swift', 'mobile-<mark>development</mark>']
      }
    },
    {
      id: '2',
      title: 'Master SwiftUI for iOS',
      description: 'Advanced techniques for creating beautiful iOS interfaces using SwiftUI framework. Build professional apps with modern development practices.',
      author: { name: 'Sarah Johnson', avatar: '👩‍💻' },
      category: 'Skills',
      tags: ['ios', 'swiftui', 'ui-design', 'development'],
      difficulty: 'Advanced',
      timeEstimate: '2-3 months',
      stats: { views: 9876, saves: 567, rating: 4.9 },
      createdAt: '2024-02-01',
      matchScore: 0.88,
      highlights: {
        title: 'Master SwiftUI for <mark>iOS</mark>',
        description: 'Advanced techniques for creating beautiful <mark>iOS</mark> interfaces',
        tags: ['<mark>ios</mark>', 'swiftui', '<mark>development</mark>']
      }
    },
    {
      id: '3',
      title: 'iOS Design Patterns',
      description: 'Essential design patterns and architectures for iOS development including MVC, MVVM, and Clean Architecture.',
      author: { name: 'Mike Williams', avatar: '🧑‍💻' },
      category: 'Skills',
      tags: ['ios', 'architecture', 'patterns', 'development'],
      difficulty: 'Advanced',
      timeEstimate: '6 weeks',
      stats: { views: 7654, saves: 432, rating: 4.7 },
      createdAt: '2024-01-20',
      matchScore: 0.82
    },
    {
      id: '4',
      title: 'Build Your First iOS Game',
      description: 'Learn game development for iOS using SpriteKit and Swift. Create engaging mobile games from scratch.',
      author: { name: 'GameDev Studio', avatar: '🎮' },
      category: 'Skills',
      tags: ['ios', 'game-development', 'spritekit', 'swift'],
      difficulty: 'Intermediate',
      timeEstimate: '2 months',
      stats: { views: 6234, saves: 345, rating: 4.6 },
      createdAt: '2024-01-10',
      matchScore: 0.75
    }
  ];

  const totalResults = 47; // Mock total
  const totalPages = Math.ceil(totalResults / resultsPerPage);

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner': return 'bg-green-100 text-green-700 border-green-200';
      case 'Intermediate': return 'bg-yellow-100 text-yellow-700 border-yellow-200';
      case 'Advanced': return 'bg-red-100 text-red-700 border-red-200';
      default: return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  const formatNumber = (num: number): string => {
    if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}k`;
    }
    return num.toString();
  };

  const getMatchBadge = (score?: number) => {
    if (!score) return null;
    if (score >= 0.9) return { text: 'Excellent Match', color: 'bg-green-100 text-green-700' };
    if (score >= 0.7) return { text: 'Good Match', color: 'bg-blue-100 text-blue-700' };
    if (score >= 0.5) return { text: 'Fair Match', color: 'bg-yellow-100 text-yellow-700' };
    return null;
  };

  const renderHighlightedText = (text: string | undefined) => {
    if (!text) return null;
    return <span dangerouslySetInnerHTML={{ __html: text }} />;
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Search Summary */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">
              Search Results for "{searchQuery}"
            </h2>
            <p className="text-gray-600 mt-1">
              Found {totalResults} wishboards matching your search
            </p>
          </div>
          
          <div className="flex items-center gap-3">
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="relevance">Most Relevant</option>
              <option value="newest">Newest First</option>
              <option value="popular">Most Popular</option>
            </select>
          </div>
        </div>

        {/* Did you mean suggestion */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-start gap-2">
          <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
          <div>
            <p className="text-sm text-blue-900">
              Did you mean: <button className="font-medium underline hover:no-underline">"iOS app development"</button>?
            </p>
          </div>
        </div>
      </div>

      {/* Search Results List */}
      <div className="space-y-4 mb-8">
        {mockResults.map((result) => {
          const matchBadge = getMatchBadge(result.matchScore);
          
          return (
            <div
              key={result.id}
              className="group bg-white rounded-xl border border-gray-200 hover:border-indigo-300 hover:shadow-lg transition-all duration-200 overflow-hidden"
            >
              <div className="p-6">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      {matchBadge && (
                        <span className={`text-xs px-2 py-1 rounded-full font-medium ${matchBadge.color}`}>
                          {matchBadge.text}
                        </span>
                      )}
                      {result.matchScore && result.matchScore >= 0.9 && (
                        <Sparkles className="w-4 h-4 text-yellow-500" />
                      )}
                    </div>
                    
                    <h3 className="text-xl font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors mb-2">
                      {result.highlights?.title ? (
                        <span dangerouslySetInnerHTML={{ __html: result.highlights.title }} />
                      ) : (
                        result.title
                      )}
                    </h3>
                    
                    <p className="text-gray-600 mb-3 line-clamp-2">
                      {result.highlights?.description ? (
                        <span dangerouslySetInnerHTML={{ __html: result.highlights.description }} />
                      ) : (
                        result.description
                      )}
                    </p>

                    <div className="flex items-center gap-4 mb-3">
                      <div className="flex items-center gap-2">
                        <span className="text-2xl">{result.author.avatar}</span>
                        <span className="text-sm text-gray-700 font-medium">{result.author.name}</span>
                      </div>
                      
                      <span className="text-gray-300">•</span>
                      
                      <span className={`px-2 py-1 rounded-lg text-xs font-medium border ${getDifficultyColor(result.difficulty)}`}>
                        {result.difficulty}
                      </span>
                      
                      <span className="flex items-center gap-1 text-sm text-gray-600">
                        <Clock className="w-4 h-4" />
                        {result.timeEstimate}
                      </span>
                      
                      <span className="px-2 py-1 bg-gray-100 text-gray-700 rounded-lg text-xs font-medium">
                        {result.category}
                      </span>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex flex-wrap gap-2">
                        {result.tags.map((tag, index) => (
                          <span
                            key={index}
                            className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg hover:bg-gray-200 transition-colors cursor-pointer"
                          >
                            {result.highlights?.tags?.[index] ? (
                              <span dangerouslySetInnerHTML={{ __html: result.highlights.tags[index] }} />
                            ) : (
                              tag
                            )}
                          </span>
                        ))}
                      </div>

                      <div className="flex items-center gap-4 text-sm text-gray-500">
                        <span className="flex items-center gap-1">
                          <Eye className="w-4 h-4" />
                          {formatNumber(result.stats.views)}
                        </span>
                        <span className="flex items-center gap-1">
                          <Bookmark className="w-4 h-4" />
                          {formatNumber(result.stats.saves)}
                        </span>
                        <span className="flex items-center gap-1">
                          <Award className="w-4 h-4" />
                          {result.stats.rating}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* No Results State */}
      {mockResults.length === 0 && (
        <div className="text-center py-12">
          <Search className="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">No results found</h3>
          <p className="text-gray-600 mb-6">
            We couldn't find any wishboards matching your search.
          </p>
          <div className="space-y-2 text-sm text-gray-600">
            <p>Try:</p>
            <ul className="list-disc list-inside space-y-1">
              <li>Using different keywords</li>
              <li>Checking your spelling</li>
              <li>Using fewer filters</li>
              <li>Browsing by category instead</li>
            </ul>
          </div>
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between pt-6 border-t border-gray-200">
          <div className="text-sm text-gray-600">
            Showing {((currentPage - 1) * resultsPerPage) + 1} to {Math.min(currentPage * resultsPerPage, totalResults)} of {totalResults} results
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            
            {[...Array(Math.min(5, totalPages))].map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`px-3 py-1 rounded-lg font-medium transition-colors ${
                    currentPage === pageNum
                      ? 'bg-indigo-500 text-white'
                      : 'hover:bg-gray-100 text-gray-700'
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
            
            {totalPages > 5 && (
              <>
                <span className="text-gray-400">...</span>
                <button
                  onClick={() => setCurrentPage(totalPages)}
                  className={`px-3 py-1 rounded-lg font-medium transition-colors ${
                    currentPage === totalPages
                      ? 'bg-indigo-500 text-white'
                      : 'hover:bg-gray-100 text-gray-700'
                  }`}
                >
                  {totalPages}
                </button>
              </>
            )}
            
            <button
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Search Tips */}
      <div className="mt-8 p-4 bg-indigo-50 rounded-lg border border-indigo-200">
        <h4 className="font-medium text-indigo-900 mb-2 flex items-center gap-2">
          <Sparkles className="w-4 h-4" />
          Pro Search Tips
        </h4>
        <ul className="text-sm text-indigo-700 space-y-1">
          <li>• Use quotes for exact phrases: "iOS development"</li>
          <li>• Exclude terms with minus: iOS -Android</li>
          <li>• Search by author: author:Alex</li>
          <li>• Filter by difficulty: difficulty:beginner</li>
        </ul>
      </div>
    </div>
  );
};

export default SearchResults;
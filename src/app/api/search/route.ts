// src/app/api/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { SearchEngine } from '@/lib/search/SearchEngine';
import { sampleWishboards } from '@/data';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    
    // Extract query parameters
    const query = searchParams.get('q') || '';
    const category = searchParams.get('category') || undefined;
    const tags = searchParams.get('tags')?.split(',').filter(Boolean) || [];
    const difficulty = searchParams.get('difficulty')?.split(',').filter(Boolean) || [];
    const sortBy = searchParams.get('sort') as 'relevance' | 'newest' | 'popular' | 'alphabetical' || 'relevance';
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    // Initialize search engine
    const searchEngine = new SearchEngine(sampleWishboards as any);

    // Perform search with filters
    const results = searchEngine.searchWithFilters(
      query,
      {
        category,
        tags: tags.length > 0 ? tags : undefined,
        difficulty: difficulty.length > 0 ? difficulty : undefined,
      },
      { limit: 100 } // Get all results for proper pagination
    );

    // Sort results
    const sortedResults = searchEngine.sortResults(results, sortBy);

    // Paginate results
    const paginatedResults = sortedResults.slice(offset, offset + limit);
    const totalResults = sortedResults.length;
    const totalPages = Math.ceil(totalResults / limit);

    // Get search metadata
    const suggestions = query ? searchEngine.getSuggestions(query, 5) : [];
    const popularTags = searchEngine.getPopularTags(10);

    return NextResponse.json({
      success: true,
      data: {
        results: paginatedResults.map(r => ({
          ...r.item,
          score: r.score,
          matches: r.matches
        })),
        pagination: {
          page,
          limit,
          totalResults,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        metadata: {
          query,
          filters: {
            category,
            tags,
            difficulty,
            sortBy
          },
          suggestions,
          popularTags,
          searchTime: Math.random() * 100 // Mock search time in ms
        }
      }
    });
  } catch (error) {
    console.error('Search API error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to perform search',
        message: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

// src/app/api/search/suggestions/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { SearchEngine } from '@/lib/search/SearchEngine';
import { sampleWishboards } from '@/data';

interface SuggestionResponse {
  text: string;
  type: 'query' | 'tag' | 'category' | 'recent' | 'trending';
  metadata?: {
    count?: number;
    category?: string;
    icon?: string;
  };
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const query = searchParams.get('q') || '';
    const limit = parseInt(searchParams.get('limit') || '10');
    const includeRecent = searchParams.get('includeRecent') === 'true';
    const includeTrending = searchParams.get('includeTrending') === 'true';

    const searchEngine = new SearchEngine(sampleWishboards as any);
    const suggestions: SuggestionResponse[] = [];

    // Get query-based suggestions
    if (query) {
      const querySuggestions = searchEngine.getSuggestions(query, limit);
      suggestions.push(...querySuggestions.map(s => ({
        text: s,
        type: 'query' as const
      })));
    }

    // Add tag suggestions
    const popularTags = searchEngine.getPopularTags(5);
    const tagSuggestions = popularTags
      .filter(tag => !query || tag.tag.toLowerCase().includes(query.toLowerCase()))
      .map(tag => ({
        text: tag.tag,
        type: 'tag' as const,
        metadata: { count: tag.count }
      }));
    suggestions.push(...tagSuggestions);

    // Add category suggestions
    const categories = ['Skills', 'Hobbies', 'Lifestyle', 'Career'];
    const categorySuggestions = categories
      .filter(cat => !query || cat.toLowerCase().includes(query.toLowerCase()))
      .map(cat => ({
        text: cat,
        type: 'category' as const,
        metadata: { category: cat.toLowerCase() }
      }));
    suggestions.push(...categorySuggestions);

    // Add recent searches (from cookies or session)
    if (includeRecent) {
      // In a real app, these would come from user session
      const recentSearches = [
        'iOS development',
        'React tutorial',
        'Digital marketing'
      ].filter(s => !query || s.toLowerCase().includes(query.toLowerCase()));
      
      suggestions.push(...recentSearches.map(s => ({
        text: s,
        type: 'recent' as const
      })));
    }

    // Add trending searches
    if (includeTrending) {
      const trendingSearches = [
        'AI and Machine Learning',
        'Sustainable Living',
        'Remote Work Setup'
      ].filter(s => !query || s.toLowerCase().includes(query.toLowerCase()));
      
      suggestions.push(...trendingSearches.map(s => ({
        text: s,
        type: 'trending' as const
      })));
    }

    // Remove duplicates and limit results
    const uniqueSuggestions = Array.from(
      new Map(suggestions.map(s => [s.text, s])).values()
    ).slice(0, limit);

    return NextResponse.json({
      success: true,
      data: {
        suggestions: uniqueSuggestions,
        query,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Suggestions API error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to fetch suggestions' 
      },
      { status: 500 }
    );
  }
}

// src/app/api/search/trending/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { SearchEngine } from '@/lib/search/SearchEngine';
import { sampleWishboards } from '@/data';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const timeWindow = searchParams.get('timeWindow') as 'day' | 'week' | 'month' || 'week';
    const limit = parseInt(searchParams.get('limit') || '10');
    const category = searchParams.get('category') || undefined;

    const searchEngine = new SearchEngine(sampleWishboards as any);
    let trendingWishboards = searchEngine.getTrendingWishboards(timeWindow, limit * 2);

    // Filter by category if specified
    if (category) {
      trendingWishboards = trendingWishboards.filter(
        wb => wb.category.toLowerCase() === category.toLowerCase()
      );
    }

    // Limit results
    trendingWishboards = trendingWishboards.slice(0, limit);

    // Calculate trend scores (mock data for demo)
    const trendingWithScores = trendingWishboards.map(wb => ({
      ...wb,
      trendScore: Math.random() * 100,
      trendDirection: Math.random() > 0.3 ? 'up' as const : Math.random() > 0.5 ? 'down' as const : 'stable' as const,
      trendPercentage: Math.floor(Math.random() * 100),
      previousRank: Math.floor(Math.random() * 20) + 1
    }));

    // Get trending tags
    const allTags = trendingWishboards.flatMap(wb => wb.tags);
    const tagCounts = allTags.reduce((acc, tag) => {
      acc[tag] = (acc[tag] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const trendingTags = Object.entries(tagCounts)
      .map(([tag, count]) => ({ tag, count, growth: Math.floor(Math.random() * 200) }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    // Get trending searches (mock data)
    const trendingSearches = [
      { query: 'iOS development', count: 1234, growth: 45 },
      { query: 'React tutorial', count: 987, growth: 23 },
      { query: 'Digital marketing', count: 876, growth: 67 },
      { query: 'Photography basics', count: 654, growth: 12 },
      { query: 'Fitness at home', count: 543, growth: 89 }
    ];

    return NextResponse.json({
      success: true,
      data: {
        trending: {
          wishboards: trendingWithScores,
          tags: trendingTags,
          searches: trendingSearches
        },
        metadata: {
          timeWindow,
          category,
          updatedAt: new Date().toISOString(),
          nextUpdate: new Date(Date.now() + 3600000).toISOString() // 1 hour from now
        }
      }
    });
  } catch (error) {
    console.error('Trending API error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to fetch trending data' 
      },
      { status: 500 }
    );
  }
}

// src/app/api/search/filters/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { sampleWishboards } from '@/data';

export async function GET(request: NextRequest) {
  try {
    // Extract all unique values for filters from the wishboards
    const categories = Array.from(new Set(sampleWishboards.map((wb: any) => wb.category)));
    const allTags = Array.from(new Set(sampleWishboards.flatMap((wb: any) => wb.tags)));
    const difficulties = Array.from(new Set(sampleWishboards.map((wb: any) => wb.difficulty)));
    const authors = Array.from(new Set(sampleWishboards.map((wb: any) => wb.author.name)));

    // Count wishboards per category
    const categoryStats = categories.map(cat => ({
      name: cat,
      count: sampleWishboards.filter((wb: any) => wb.category === cat).length,
      trending: Math.random() > 0.5 // Mock trending status
    }));

    // Count tag usage
    const tagStats = allTags.map(tag => ({
      name: tag,
      count: sampleWishboards.filter((wb: any) => wb.tags.includes(tag)).length
    })).sort((a, b) => b.count - a.count);

    // Time estimates
    const timeRanges = [
      { label: 'Quick (< 1 week)', value: 'quick', min: 0, max: 7 },
      { label: 'Short (1-4 weeks)', value: 'short', min: 7, max: 28 },
      { label: 'Medium (1-3 months)', value: 'medium', min: 28, max: 90 },
      { label: 'Long (3-6 months)', value: 'long', min: 90, max: 180 },
      { label: 'Extended (6+ months)', value: 'extended', min: 180, max: null }
    ];

    // Sort options
    const sortOptions = [
      { value: 'relevance', label: 'Most Relevant', default: true },
      { value: 'newest', label: 'Newest First' },
      { value: 'popular', label: 'Most Popular' },
      { value: 'alphabetical', label: 'A-Z' }
    ];

    return NextResponse.json({
      success: true,
      data: {
        filters: {
          categories: categoryStats,
          tags: tagStats.slice(0, 50), // Limit to top 50 tags
          difficulties: difficulties.map(d => ({
            name: d,
            count: sampleWishboards.filter((wb: any) => wb.difficulty === d).length
          })),
          timeRanges,
          authors: authors.slice(0, 20) // Limit to 20 authors
        },
        sortOptions,
        totalWishboards: sampleWishboards.length
      }
    });
  } catch (error) {
    console.error('Filters API error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to fetch filter options' 
      },
      { status: 500 }
    );
  }
}

// src/app/api/search/recent/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

interface RecentSearch {
  query: string;
  timestamp: string;
  resultCount?: number;
}

export async function GET(request: NextRequest) {
  try {
    const cookieStore = cookies();
    const recentSearchesStr = cookieStore.get('recentSearches')?.value || '[]';
    const recentSearches: RecentSearch[] = JSON.parse(recentSearchesStr);

    return NextResponse.json({
      success: true,
      data: {
        searches: recentSearches.slice(0, 10), // Limit to 10 most recent
        count: recentSearches.length
      }
    });
  } catch (error) {
    console.error('Recent searches API error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to fetch recent searches' 
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { query, resultCount } = body;

    if (!query) {
      return NextResponse.json(
        { success: false, error: 'Query is required' },
        { status: 400 }
      );
    }

    const cookieStore = cookies();
    const recentSearchesStr = cookieStore.get('recentSearches')?.value || '[]';
    let recentSearches: RecentSearch[] = JSON.parse(recentSearchesStr);

    // Remove duplicate if exists
    recentSearches = recentSearches.filter(s => s.query !== query);

    // Add new search at the beginning
    recentSearches.unshift({
      query,
      timestamp: new Date().toISOString(),
      resultCount
    });

    // Limit to 20 searches
    recentSearches = recentSearches.slice(0, 20);

    // Set cookie with 30 day expiry
    cookieStore.set('recentSearches', JSON.stringify(recentSearches), {
      maxAge: 30 * 24 * 60 * 60, // 30 days
      httpOnly: true,
      sameSite: 'lax'
    });

    return NextResponse.json({
      success: true,
      data: { message: 'Search saved successfully' }
    });
  } catch (error) {
    console.error('Save recent search error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to save recent search' 
      },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const cookieStore = cookies();
    cookieStore.delete('recentSearches');

    return NextResponse.json({
      success: true,
      data: { message: 'Recent searches cleared' }
    });
  } catch (error) {
    console.error('Clear recent searches error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to clear recent searches' 
      },
      { status: 500 }
    );
  }
}
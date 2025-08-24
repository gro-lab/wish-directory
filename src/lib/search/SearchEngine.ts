// src/lib/search/SearchEngine.ts
import Fuse from 'fuse.js';
import { Wishboard, WishboardItem } from '@/lib/types';

interface SearchOptions {
  threshold?: number;
  limit?: number;
  includeScore?: boolean;
  keys?: string[];
}

interface SearchResult {
  item: Wishboard;
  score?: number;
  matches?: any[];
  refIndex?: number;
}

export class SearchEngine {
  private fuse: Fuse<Wishboard> | null = null;
  private wishboards: Wishboard[] = [];
  
  private defaultOptions: Fuse.IFuseOptions<Wishboard> = {
    threshold: 0.3,
    includeScore: true,
    includeMatches: true,
    minMatchCharLength: 2,
    shouldSort: true,
    findAllMatches: false,
    keys: [
      { name: 'title', weight: 0.3 },
      { name: 'description', weight: 0.2 },
      { name: 'tags', weight: 0.2 },
      { name: 'category', weight: 0.15 },
      { name: 'author.name', weight: 0.1 },
      { name: 'items.title', weight: 0.05 }
    ],
    getFn: (obj, path) => {
      const value = Fuse.config.getFn(obj, path);
      if (Array.isArray(value)) {
        return value.join(' ');
      }
      return value;
    }
  };

  constructor(wishboards: Wishboard[] = []) {
    this.initialize(wishboards);
  }

  initialize(wishboards: Wishboard[]) {
    this.wishboards = wishboards;
    this.fuse = new Fuse(wishboards, this.defaultOptions);
  }

  search(query: string, options: SearchOptions = {}): SearchResult[] {
    if (!this.fuse || !query.trim()) {
      return this.wishboards.map(item => ({ item }));
    }

    const searchOptions = {
      ...this.defaultOptions,
      ...options
    };

    const results = this.fuse.search(query, { limit: options.limit || 20 });
    
    return results.map(result => ({
      item: result.item,
      score: result.score,
      matches: result.matches,
      refIndex: result.refIndex
    }));
  }

  searchWithFilters(
    query: string,
    filters: {
      category?: string;
      tags?: string[];
      difficulty?: string[];
      minTime?: string;
      maxTime?: string;
      author?: string;
    },
    options: SearchOptions = {}
  ): SearchResult[] {
    let results = query.trim() 
      ? this.search(query, options)
      : this.wishboards.map(item => ({ item }));

    // Apply category filter
    if (filters.category) {
      results = results.filter(r => 
        r.item.category.toLowerCase() === filters.category!.toLowerCase()
      );
    }

    // Apply tag filter
    if (filters.tags && filters.tags.length > 0) {
      results = results.filter(r => 
        filters.tags!.some(tag => 
          r.item.tags.some(t => t.toLowerCase().includes(tag.toLowerCase()))
        )
      );
    }

    // Apply difficulty filter
    if (filters.difficulty && filters.difficulty.length > 0) {
      results = results.filter(r => 
        filters.difficulty!.includes(r.item.difficulty)
      );
    }

    // Apply author filter
    if (filters.author) {
      results = results.filter(r => 
        r.item.author.name.toLowerCase().includes(filters.author!.toLowerCase())
      );
    }

    return results;
  }

  getSuggestions(partial: string, limit: number = 5): string[] {
    if (!partial.trim() || partial.length < 2) return [];

    const suggestions = new Set<string>();
    
    // Search in titles
    this.wishboards.forEach(wb => {
      if (wb.title.toLowerCase().includes(partial.toLowerCase())) {
        suggestions.add(wb.title);
      }
    });

    // Search in tags
    this.wishboards.forEach(wb => {
      wb.tags.forEach(tag => {
        if (tag.toLowerCase().includes(partial.toLowerCase())) {
          suggestions.add(tag);
        }
      });
    });

    return Array.from(suggestions).slice(0, limit);
  }

  getPopularTags(limit: number = 20): { tag: string; count: number }[] {
    const tagCounts = new Map<string, number>();
    
    this.wishboards.forEach(wb => {
      wb.tags.forEach(tag => {
        tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1);
      });
    });

    return Array.from(tagCounts.entries())
      .map(([tag, count]) => ({ tag, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  getTrendingWishboards(timeWindow: 'day' | 'week' | 'month' = 'week', limit: number = 10): Wishboard[] {
    const now = new Date();
    const windowMs = {
      day: 24 * 60 * 60 * 1000,
      week: 7 * 24 * 60 * 60 * 1000,
      month: 30 * 24 * 60 * 60 * 1000
    };

    return this.wishboards
      .filter(wb => {
        const createdAt = new Date(wb.createdAt);
        return (now.getTime() - createdAt.getTime()) < windowMs[timeWindow];
      })
      .sort((a, b) => {
        // Sort by views and saves
        const scoreA = (a.stats.views * 0.3) + (a.stats.saves * 0.7);
        const scoreB = (b.stats.views * 0.3) + (b.stats.saves * 0.7);
        return scoreB - scoreA;
      })
      .slice(0, limit);
  }

  sortResults(
    results: SearchResult[],
    sortBy: 'relevance' | 'newest' | 'popular' | 'alphabetical' = 'relevance'
  ): SearchResult[] {
    const sorted = [...results];

    switch (sortBy) {
      case 'relevance':
        return sorted.sort((a, b) => (a.score || 0) - (b.score || 0));
      
      case 'newest':
        return sorted.sort((a, b) => 
          new Date(b.item.createdAt).getTime() - new Date(a.item.createdAt).getTime()
        );
      
      case 'popular':
        return sorted.sort((a, b) => {
          const scoreA = (a.item.stats.views * 0.3) + (a.item.stats.saves * 0.7);
          const scoreB = (b.item.stats.views * 0.3) + (b.item.stats.saves * 0.7);
          return scoreB - scoreA;
        });
      
      case 'alphabetical':
        return sorted.sort((a, b) => 
          a.item.title.localeCompare(b.item.title)
        );
      
      default:
        return sorted;
    }
  }

  updateIndex(wishboards: Wishboard[]) {
    this.initialize(wishboards);
  }

  clearIndex() {
    this.wishboards = [];
    this.fuse = null;
  }
}
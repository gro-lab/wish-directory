// src/lib/types.ts

// User Types
export interface User {
  id: string;
  name: string;
  avatar: string;
  bio?: string;
  email?: string;
  role?: 'viewer' | 'creator' | 'admin';
  createdAt?: string;
  updatedAt?: string;
}

// Wishboard Item Types
export type ItemType = 'itunes' | 'affiliate' | 'custom';

export interface BaseItem {
  id: string;
  type: ItemType;
  title: string;
  description?: string;
  url: string;
  imageUrl?: string;
  price?: string;
  position?: number;
}

export interface ITunesItem extends BaseItem {
  type: 'itunes';
  source: 'itunes';
  itunesId: string;
  appStoreUrl?: string;
  category?: string;
  rating?: number;
  ratingCount?: number;
}

export interface AffiliateItem extends BaseItem {
  type: 'affiliate';
  affiliateSource: string;
  affiliateTag?: string;
  originalPrice?: string;
  discountPercentage?: number;
  commission?: number;
}

export interface CustomItem extends BaseItem {
  type: 'custom';
  customData?: Record<string, any>;
}

export type WishboardItem = ITunesItem | AffiliateItem | CustomItem;

// Wishboard Types
export type Difficulty = 'Beginner' | 'Intermediate' | 'Advanced';
export type Category = 'Skills' | 'Hobbies' | 'Lifestyle' | 'Career';

export interface WishboardStats {
  views: number;
  saves: number;
  shares: number;
  rating?: number;
  ratingCount?: number;
}

export interface Wishboard {
  id: string;
  title: string;
  description: string;
  author: User;
  category: Category;
  tags: string[];
  difficulty: Difficulty;
  estimatedTime: string;
  items: WishboardItem[];
  stats: WishboardStats;
  isPublic: boolean;
  isDraft: boolean;
  featured?: boolean;
  coverImage?: string;
  createdAt: string;
  updatedAt: string;
}

// Search Types
export interface SearchFilters {
  category?: string;
  tags?: string[];
  difficulty?: Difficulty[];
  minTime?: string;
  maxTime?: string;
  author?: string;
  priceRange?: {
    min: number;
    max: number;
  };
  dateRange?: {
    start: Date | null;
    end: Date | null;
  };
}

export interface SearchResult {
  item: Wishboard;
  score?: number;
  matches?: Array<{
    indices: Array<[number, number]>;
    value: string;
    key: string;
  }>;
  highlights?: {
    title?: string;
    description?: string;
    tags?: string[];
  };
}

export interface SearchSuggestion {
  text: string;
  type: 'query' | 'tag' | 'category' | 'author' | 'recent' | 'trending';
  metadata?: {
    count?: number;
    category?: string;
    icon?: string;
  };
}

// Analytics Types
export interface AnalyticsEvent {
  event: string;
  properties: Record<string, any>;
  userId?: string;
  timestamp: string;
}

export interface TrendingData {
  wishboard: Wishboard;
  trendScore: number;
  trendDirection: 'up' | 'down' | 'stable';
  trendPercentage: number;
  previousRank?: number;
  currentRank: number;
}

// Filter Types
export interface FilterOption {
  value: string;
  label: string;
  count?: number;
  disabled?: boolean;
}

export interface FilterSection {
  id: string;
  title: string;
  type: 'single' | 'multiple' | 'range' | 'text';
  options?: FilterOption[];
  value?: any;
}

// Pagination Types
export interface PaginationInfo {
  page: number;
  limit: number;
  totalResults: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    message: string;
    code?: string;
    details?: any;
  };
  metadata?: Record<string, any>;
}

export interface SearchApiResponse {
  results: SearchResult[];
  pagination: PaginationInfo;
  metadata: {
    query: string;
    filters: SearchFilters;
    suggestions: string[];
    popularTags: Array<{ tag: string; count: number }>;
    searchTime: number;
  };
}

// State Types
export interface SearchState {
  query: string;
  filters: SearchFilters;
  results: Wishboard[];
  isSearching: boolean;
  error: Error | null;
  totalResults: number;
  suggestions: SearchSuggestion[];
  recentSearches: string[];
  popularTags: Array<{ tag: string; count: number }>;
  hasSearched: boolean;
  currentPage: number;
  sortBy: 'relevance' | 'newest' | 'popular' | 'alphabetical';
}

export interface FilterState {
  category: string;
  tags: string[];
  difficulty: Difficulty[];
  timeRange: { min: string; max: string };
  priceRange: { min: number; max: number };
  sortBy: 'relevance' | 'newest' | 'popular' | 'alphabetical';
}

// UI Component Props Types
export interface WishboardCardProps {
  wishboard: Wishboard;
  variant?: 'default' | 'compact' | 'detailed';
  showStats?: boolean;
  showAuthor?: boolean;
  onSave?: (id: string) => void;
  onShare?: (id: string) => void;
  onClick?: (wishboard: Wishboard) => void;
}

export interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  onSearch: (query: string) => void;
  suggestions?: SearchSuggestion[];
  isLoading?: boolean;
  placeholder?: string;
  autoFocus?: boolean;
}

export interface FilterSidebarProps {
  filters: FilterState;
  onFilterChange: (filters: FilterState) => void;
  availableFilters: {
    categories: Array<{ name: string; count: number }>;
    tags: Array<{ name: string; count: number }>;
    difficulties: Difficulty[];
    authors: string[];
  };
  isOpen: boolean;
  onClose: () => void;
}

// Utility Types
export type SortOption = 'relevance' | 'newest' | 'popular' | 'alphabetical';
export type TimeWindow = 'day' | 'week' | 'month' | 'year' | 'all';
export type ViewMode = 'grid' | 'list' | 'compact';

// Enum Definitions
export enum ItemTypeEnum {
  ITUNES = 'itunes',
  AFFILIATE = 'affiliate',
  CUSTOM = 'custom'
}

export enum DifficultyLevel {
  BEGINNER = 'Beginner',
  INTERMEDIATE = 'Intermediate',
  ADVANCED = 'Advanced'
}

export enum CategoryEnum {
  SKILLS = 'Skills',
  HOBBIES = 'Hobbies',
  LIFESTYLE = 'Lifestyle',
  CAREER = 'Career'
}

// Type Guards
export function isITunesItem(item: WishboardItem): item is ITunesItem {
  return item.type === 'itunes';
}

export function isAffiliateItem(item: WishboardItem): item is AffiliateItem {
  return item.type === 'affiliate';
}

export function isCustomItem(item: WishboardItem): item is CustomItem {
  return item.type === 'custom';
}

// Constants
export const DIFFICULTY_LEVELS: Difficulty[] = ['Beginner', 'Intermediate', 'Advanced'];
export const CATEGORIES: Category[] = ['Skills', 'Hobbies', 'Lifestyle', 'Career'];
export const SORT_OPTIONS: SortOption[] = ['relevance', 'newest', 'popular', 'alphabetical'];
export const TIME_WINDOWS: TimeWindow[] = ['day', 'week', 'month', 'year', 'all'];
export const VIEW_MODES: ViewMode[] = ['grid', 'list', 'compact'];

export const DEFAULT_FILTERS: FilterState = {
  category: '',
  tags: [],
  difficulty: [],
  timeRange: { min: '', max: '' },
  priceRange: { min: 0, max: 1000 },
  sortBy: 'relevance'
};

export const DEFAULT_PAGINATION: PaginationInfo = {
  page: 1,
  limit: 20,
  totalResults: 0,
  totalPages: 0,
  hasNext: false,
  hasPrev: false
};
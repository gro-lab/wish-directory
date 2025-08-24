// src/components/browse/CategoryBrowser.tsx
import React, { useState } from 'react';
import { 
  Briefcase, 
  Heart, 
  Sparkles, 
  Code, 
  TrendingUp, 
  Clock, 
  Award,
  Zap,
  Users,
  ArrowRight,
  ChevronRight,
  Star,
  Eye,
  Bookmark
} from 'lucide-react';

interface Category {
  id: string;
  name: string;
  description: string;
  icon: React.ReactNode;
  color: string;
  count: number;
  trending: boolean;
}

interface TrendingItem {
  id: string;
  title: string;
  author: string;
  category: string;
  views: number;
  saves: number;
  trend: 'up' | 'down' | 'stable';
  trendPercentage: number;
  timeEstimate: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  tags: string[];
}

const CategoryBrowser: React.FC = () => {
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [trendingTimeframe, setTrendingTimeframe] = useState<'today' | 'week' | 'month'>('week');

  const categories: Category[] = [
    {
      id: 'skills',
      name: 'Skills',
      description: 'Learn new abilities and professional competencies',
      icon: <Code className="w-6 h-6" />,
      color: 'bg-blue-500',
      count: 342,
      trending: true
    },
    {
      id: 'hobbies',
      name: 'Hobbies',
      description: 'Explore creative pursuits and personal interests',
      icon: <Heart className="w-6 h-6" />,
      color: 'bg-pink-500',
      count: 256,
      trending: false
    },
    {
      id: 'lifestyle',
      name: 'Lifestyle',
      description: 'Improve your daily life and wellness',
      icon: <Sparkles className="w-6 h-6" />,
      color: 'bg-purple-500',
      count: 189,
      trending: true
    },
    {
      id: 'career',
      name: 'Career',
      description: 'Advance your professional journey',
      icon: <Briefcase className="w-6 h-6" />,
      color: 'bg-green-500',
      count: 167,
      trending: false
    }
  ];

  const trendingItems: TrendingItem[] = [
    {
      id: '1',
      title: 'Learn iOS App Development',
      author: 'Alex Chen',
      category: 'Skills',
      views: 15234,
      saves: 892,
      trend: 'up',
      trendPercentage: 45,
      timeEstimate: '3-6 months',
      difficulty: 'Intermediate',
      tags: ['programming', 'mobile', 'swift']
    },
    {
      id: '2',
      title: 'Start Digital Minimalism',
      author: 'Sarah Johnson',
      category: 'Lifestyle',
      views: 9876,
      saves: 567,
      trend: 'up',
      trendPercentage: 23,
      timeEstimate: '30 days',
      difficulty: 'Beginner',
      tags: ['productivity', 'minimalism', 'digital-detox']
    },
    {
      id: '3',
      title: 'Master Home Cooking',
      author: 'Chef Marcus',
      category: 'Hobbies',
      views: 8432,
      saves: 432,
      trend: 'stable',
      trendPercentage: 2,
      timeEstimate: '2-3 months',
      difficulty: 'Beginner',
      tags: ['cooking', 'food', 'recipes']
    },
    {
      id: '4',
      title: 'Build a Personal Brand',
      author: 'Maya Patel',
      category: 'Career',
      views: 7654,
      saves: 398,
      trend: 'up',
      trendPercentage: 67,
      timeEstimate: '6 weeks',
      difficulty: 'Advanced',
      tags: ['marketing', 'personal-brand', 'social-media']
    },
    {
      id: '5',
      title: 'Learn UI/UX Design',
      author: 'Design Studio',
      category: 'Skills',
      views: 6789,
      saves: 345,
      trend: 'up',
      trendPercentage: 34,
      timeEstimate: '4 months',
      difficulty: 'Intermediate',
      tags: ['design', 'ui', 'ux', 'figma']
    }
  ];

  const risingStars = [
    { title: 'Meditation for Beginners', growth: '+892%', category: 'Lifestyle' },
    { title: 'No-Code App Building', growth: '+567%', category: 'Skills' },
    { title: 'Urban Gardening 101', growth: '+423%', category: 'Hobbies' },
    { title: 'Remote Work Excellence', growth: '+378%', category: 'Career' }
  ];

  const popularTags = [
    { name: 'programming', heat: 98 },
    { name: 'productivity', heat: 89 },
    { name: 'design', heat: 76 },
    { name: 'fitness', heat: 72 },
    { name: 'mindfulness', heat: 68 },
    { name: 'cooking', heat: 65 },
    { name: 'photography', heat: 61 },
    { name: 'writing', heat: 58 },
    { name: 'music', heat: 55 },
    { name: 'art', heat: 52 }
  ];

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner': return 'bg-green-100 text-green-700';
      case 'Intermediate': return 'bg-yellow-100 text-yellow-700';
      case 'Advanced': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const formatNumber = (num: number): string => {
    if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}k`;
    }
    return num.toString();
  };

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* Categories Grid */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Browse by Category</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {categories.map((category) => (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className="group relative p-6 bg-white rounded-xl border border-gray-200 hover:border-gray-300 hover:shadow-lg transition-all duration-200 text-left"
            >
              {category.trending && (
                <span className="absolute top-3 right-3 px-2 py-1 bg-red-100 text-red-600 text-xs font-medium rounded-full flex items-center gap-1">
                  <TrendingUp className="w-3 h-3" />
                  Trending
                </span>
              )}
              
              <div className={`w-12 h-12 ${category.color} rounded-lg flex items-center justify-center text-white mb-4`}>
                {category.icon}
              </div>
              
              <h3 className="text-lg font-semibold text-gray-900 mb-2 group-hover:text-indigo-600 transition-colors">
                {category.name}
              </h3>
              
              <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                {category.description}
              </p>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-500">{category.count} wishboards</span>
                <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-indigo-600 group-hover:translate-x-1 transition-all" />
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Trending Section */}
      <div className="mb-12">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <TrendingUp className="w-6 h-6 text-indigo-500" />
            Trending Now
          </h2>
          <div className="flex gap-2">
            {(['today', 'week', 'month'] as const).map((timeframe) => (
              <button
                key={timeframe}
                onClick={() => setTrendingTimeframe(timeframe)}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-all ${
                  trendingTimeframe === timeframe
                    ? 'bg-indigo-500 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {timeframe === 'today' ? 'Today' : timeframe === 'week' ? 'This Week' : 'This Month'}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {trendingItems.map((item) => (
            <div
              key={item.id}
              className="group bg-white rounded-xl border border-gray-200 hover:border-indigo-300 hover:shadow-lg transition-all duration-200 overflow-hidden"
            >
              <div className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1">
                      {item.title}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">by {item.author}</p>
                  </div>
                  <div className="flex items-center gap-1">
                    {item.trend === 'up' && (
                      <>
                        <TrendingUp className="w-4 h-4 text-green-500" />
                        <span className="text-xs font-medium text-green-600">+{item.trendPercentage}%</span>
                      </>
                    )}
                    {item.trend === 'stable' && (
                      <span className="text-xs font-medium text-gray-500">±{item.trendPercentage}%</span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-2 mb-3">
                  <span className={`px-2 py-1 rounded text-xs font-medium ${getDifficultyColor(item.difficulty)}`}>
                    {item.difficulty}
                  </span>
                  <span className="text-xs text-gray-500">•</span>
                  <span className="text-xs text-gray-500">{item.timeEstimate}</span>
                  <span className="text-xs text-gray-500">•</span>
                  <span className="text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded">
                    {item.category}
                  </span>
                </div>

                <div className="flex items-center gap-4 text-sm text-gray-500">
                  <span className="flex items-center gap-1">
                    <Eye className="w-4 h-4" />
                    {formatNumber(item.views)}
                  </span>
                  <span className="flex items-center gap-1">
                    <Bookmark className="w-4 h-4" />
                    {formatNumber(item.saves)}
                  </span>
                </div>

                <div className="flex flex-wrap gap-1 mt-3">
                  {item.tags.slice(0, 3).map((tag) => (
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
          ))}
        </div>
      </div>

      {/* Rising Stars & Tag Cloud */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Rising Stars */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Zap className="w-5 h-5 text-yellow-500" />
            Rising Stars
          </h3>
          <div className="space-y-3">
            {risingStars.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-900">{item.title}</p>
                  <p className="text-xs text-gray-500">{item.category}</p>
                </div>
                <span className="text-sm font-bold text-green-600">{item.growth}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Popular Tags */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Award className="w-5 h-5 text-indigo-500" />
            Hot Topics
          </h3>
          <div className="flex flex-wrap gap-2">
            {popularTags.map((tag) => {
              const size = tag.heat > 80 ? 'text-base' : tag.heat > 60 ? 'text-sm' : 'text-xs';
              const color = tag.heat > 80 ? 'bg-indigo-500 text-white' : tag.heat > 60 ? 'bg-indigo-100 text-indigo-700' : 'bg-gray-100 text-gray-700';
              
              return (
                <button
                  key={tag.name}
                  className={`px-3 py-1.5 rounded-lg font-medium hover:scale-105 transition-transform ${size} ${color}`}
                >
                  {tag.name}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};

export default CategoryBrowser;
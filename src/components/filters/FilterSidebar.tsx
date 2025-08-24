// src/components/filters/FilterSidebar.tsx
import React, { useState } from 'react';
import { 
  X, 
  ChevronDown, 
  ChevronUp,
  Filter,
  Clock,
  Award,
  Tag,
  User,
  Calendar,
  DollarSign,
  RotateCcw
} from 'lucide-react';

interface FilterSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  filters: any;
  onFilterChange: (filters: any) => void;
  availableFilters: {
    categories: { name: string; count: number }[];
    tags: { name: string; count: number }[];
    difficulties: string[];
    authors: string[];
  };
}

const FilterSidebar: React.FC<FilterSidebarProps> = ({
  isOpen,
  onClose,
  filters,
  onFilterChange,
  availableFilters
}) => {
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(['category', 'tags', 'difficulty'])
  );

  const toggleSection = (section: string) => {
    const newExpanded = new Set(expandedSections);
    if (newExpanded.has(section)) {
      newExpanded.delete(section);
    } else {
      newExpanded.add(section);
    }
    setExpandedSections(newExpanded);
  };

  const clearAllFilters = () => {
    onFilterChange({
      category: '',
      tags: [],
      difficulty: [],
      timeRange: { min: '', max: '' },
      priceRange: { min: 0, max: 1000 },
      author: '',
      dateRange: { start: null, end: null }
    });
  };

  const activeFilterCount = 
    (filters.category ? 1 : 0) +
    filters.tags.length +
    filters.difficulty.length +
    (filters.timeRange.min || filters.timeRange.max ? 1 : 0) +
    (filters.author ? 1 : 0);

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed lg:sticky top-0 left-0 h-full lg:h-auto
        w-80 bg-white border-r border-gray-200
        transform transition-transform duration-300 ease-in-out
        z-50 lg:z-0 overflow-y-auto
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Filter className="w-5 h-5 text-gray-700" />
              <h2 className="text-lg font-semibold text-gray-900">Filters</h2>
              {activeFilterCount > 0 && (
                <span className="bg-indigo-500 text-white text-xs px-2 py-1 rounded-full">
                  {activeFilterCount}
                </span>
              )}
            </div>
            <div className="flex items-center gap-2">
              {activeFilterCount > 0 && (
                <button
                  onClick={clearAllFilters}
                  className="text-sm text-indigo-600 hover:text-indigo-700 flex items-center gap-1"
                >
                  <RotateCcw className="w-4 h-4" />
                  Clear
                </button>
              )}
              <button
                onClick={onClose}
                className="lg:hidden p-1 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>
          </div>
        </div>

        <div className="p-4 space-y-6">
          {/* Category Filter */}
          <FilterSection
            title="Category"
            icon={<Award className="w-4 h-4" />}
            isExpanded={expandedSections.has('category')}
            onToggle={() => toggleSection('category')}
            badge={filters.category ? '1' : undefined}
          >
            <div className="space-y-2">
              {availableFilters.categories.map(cat => (
                <label
                  key={cat.name}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
                >
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      name="category"
                      value={cat.name}
                      checked={filters.category === cat.name}
                      onChange={(e) => onFilterChange({
                        ...filters,
                        category: e.target.checked ? cat.name : ''
                      })}
                      className="text-indigo-500 focus:ring-indigo-500"
                    />
                    <span className="text-sm text-gray-700">{cat.name}</span>
                  </div>
                  <span className="text-xs text-gray-500">{cat.count}</span>
                </label>
              ))}
            </div>
          </FilterSection>

          {/* Tags Filter */}
          <FilterSection
            title="Tags"
            icon={<Tag className="w-4 h-4" />}
            isExpanded={expandedSections.has('tags')}
            onToggle={() => toggleSection('tags')}
            badge={filters.tags.length > 0 ? filters.tags.length.toString() : undefined}
          >
            <div className="space-y-2 max-h-60 overflow-y-auto">
              {availableFilters.tags.slice(0, 20).map(tag => (
                <label
                  key={tag.name}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
                >
                  <div className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      value={tag.name}
                      checked={filters.tags.includes(tag.name)}
                      onChange={(e) => {
                        const newTags = e.target.checked
                          ? [...filters.tags, tag.name]
                          : filters.tags.filter((t: string) => t !== tag.name);
                        onFilterChange({ ...filters, tags: newTags });
                      }}
                      className="text-indigo-500 focus:ring-indigo-500 rounded"
                    />
                    <span className="text-sm text-gray-700">{tag.name}</span>
                  </div>
                  <span className="text-xs text-gray-500">{tag.count}</span>
                </label>
              ))}
            </div>
          </FilterSection>

          {/* Difficulty Filter */}
          <FilterSection
            title="Difficulty"
            icon={<Award className="w-4 h-4" />}
            isExpanded={expandedSections.has('difficulty')}
            onToggle={() => toggleSection('difficulty')}
            badge={filters.difficulty.length > 0 ? filters.difficulty.length.toString() : undefined}
          >
            <div className="space-y-2">
              {availableFilters.difficulties.map(level => (
                <label
                  key={level}
                  className="flex items-center gap-2 p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    value={level}
                    checked={filters.difficulty.includes(level)}
                    onChange={(e) => {
                      const newDifficulty = e.target.checked
                        ? [...filters.difficulty, level]
                        : filters.difficulty.filter((d: string) => d !== level);
                      onFilterChange({ ...filters, difficulty: newDifficulty });
                    }}
                    className="text-indigo-500 focus:ring-indigo-500 rounded"
                  />
                  <span className="text-sm text-gray-700">{level}</span>
                  <DifficultyIndicator level={level} />
                </label>
              ))}
            </div>
          </FilterSection>

          {/* Time Range Filter */}
          <FilterSection
            title="Time Commitment"
            icon={<Clock className="w-4 h-4" />}
            isExpanded={expandedSections.has('time')}
            onToggle={() => toggleSection('time')}
            badge={filters.timeRange.min || filters.timeRange.max ? '1' : undefined}
          >
            <TimeRangeFilter
              value={filters.timeRange}
              onChange={(timeRange) => onFilterChange({ ...filters, timeRange })}
            />
          </FilterSection>

          {/* Author Filter */}
          <FilterSection
            title="Author"
            icon={<User className="w-4 h-4" />}
            isExpanded={expandedSections.has('author')}
            onToggle={() => toggleSection('author')}
            badge={filters.author ? '1' : undefined}
          >
            <input
              type="text"
              placeholder="Search by author..."
              value={filters.author || ''}
              onChange={(e) => onFilterChange({ ...filters, author: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <div className="mt-2 space-y-1">
              {availableFilters.authors.slice(0, 5).map(author => (
                <button
                  key={author}
                  onClick={() => onFilterChange({ ...filters, author })}
                  className="block w-full text-left px-2 py-1 text-sm text-gray-600 hover:bg-gray-50 rounded"
                >
                  {author}
                </button>
              ))}
            </div>
          </FilterSection>
        </div>

        {/* Apply Button (Mobile) */}
        <div className="sticky bottom-0 bg-white border-t border-gray-200 p-4 lg:hidden">
          <button
            onClick={onClose}
            className="w-full py-2 bg-indigo-500 text-white rounded-lg hover:bg-indigo-600 transition-colors"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </>
  );
};

// Filter Section Component
interface FilterSectionProps {
  title: string;
  icon: React.ReactNode;
  isExpanded: boolean;
  onToggle: () => void;
  badge?: string;
  children: React.ReactNode;
}

const FilterSection: React.FC<FilterSectionProps> = ({
  title,
  icon,
  isExpanded,
  onToggle,
  badge,
  children
}) => {
  return (
    <div className="border-b border-gray-200 last:border-0 pb-4 last:pb-0">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between py-2 hover:text-indigo-600 transition-colors"
      >
        <div className="flex items-center gap-2">
          {icon}
          <span className="font-medium text-gray-900">{title}</span>
          {badge && (
            <span className="bg-indigo-100 text-indigo-700 text-xs px-2 py-0.5 rounded-full">
              {badge}
            </span>
          )}
        </div>
        {isExpanded ? (
          <ChevronUp className="w-4 h-4 text-gray-500" />
        ) : (
          <ChevronDown className="w-4 h-4 text-gray-500" />
        )}
      </button>
      {isExpanded && (
        <div className="mt-3">
          {children}
        </div>
      )}
    </div>
  );
};

// Difficulty Indicator Component
const DifficultyIndicator: React.FC<{ level: string }> = ({ level }) => {
  const getColor = () => {
    switch (level) {
      case 'Beginner': return 'bg-green-500';
      case 'Intermediate': return 'bg-yellow-500';
      case 'Advanced': return 'bg-red-500';
      default: return 'bg-gray-500';
    }
  };

  const getFilledDots = () => {
    switch (level) {
      case 'Beginner': return 1;
      case 'Intermediate': return 2;
      case 'Advanced': return 3;
      default: return 0;
    }
  };

  const filledDots = getFilledDots();

  return (
    <div className="flex gap-1 ml-auto">
      {[1, 2, 3].map(dot => (
        <div
          key={dot}
          className={`w-2 h-2 rounded-full ${
            dot <= filledDots ? getColor() : 'bg-gray-300'
          }`}
        />
      ))}
    </div>
  );
};

// Time Range Filter Component
interface TimeRangeFilterProps {
  value: { min: string; max: string };
  onChange: (value: { min: string; max: string }) => void;
}

const TimeRangeFilter: React.FC<TimeRangeFilterProps> = ({ value, onChange }) => {
  const presets = [
    { label: 'Quick (< 1 week)', min: '0', max: '7' },
    { label: 'Short (1-4 weeks)', min: '7', max: '28' },
    { label: 'Medium (1-3 months)', min: '28', max: '90' },
    { label: 'Long (3-6 months)', min: '90', max: '180' },
  ];

  return (
    <div className="space-y-3">
      <div className="space-y-2">
        {presets.map(preset => (
          <button
            key={preset.label}
            onClick={() => onChange({ min: preset.min, max: preset.max })}
            className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
              value.min === preset.min && value.max === preset.max
                ? 'bg-indigo-100 text-indigo-700'
                : 'hover:bg-gray-50 text-gray-700'
            }`}
          >
            {preset.label}
          </button>
        ))}
      </div>
      
      <div className="pt-3 border-t border-gray-200">
        <label className="text-xs text-gray-600 font-medium">Custom Range (days)</label>
        <div className="flex gap-2 mt-2">
          <input
            type="number"
            placeholder="Min"
            value={value.min}
            onChange={(e) => onChange({ ...value, min: e.target.value })}
            className="flex-1 px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
          <span className="text-gray-500 self-center">-</span>
          <input
            type="number"
            placeholder="Max"
            value={value.max}
            onChange={(e) => onChange({ ...value, max: e.target.value })}
            className="flex-1 px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>
      </div>
    </div>
  );
};

export default FilterSidebar;
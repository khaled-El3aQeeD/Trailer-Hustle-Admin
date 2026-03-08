# Dashboard Template

A business dashboard template built with Flutter Web and Forui design system (https://forui.dev/). Features responsive layouts, interactive charts, KPI metrics, and clean architecture for data-driven applications.

## 🚀 Quick Start

Works immediately with sample data - see charts, metrics, and responsive layout in action!

**Features:**
- 📊 Interactive charts with time period switching
- 📈 KPI metric cards with trend indicators  
- 👥 Team performance leaderboards
- 📋 Activity feeds and progress tracking
- 📱 Responsive layout (mobile ↔ tablet ↔ desktop)
- 🌙 Light/dark theme switching

## 🏗️ Architecture

```
📱 UI Layer - DashboardPage, cards, charts, sidebar
🎨 Theme Layer - Forui design system integration  
📊 Data Layer - Static sample data, models
```

**Key Components:**
- **DashboardPage**: Responsive layout with collapsible sidebar
- **MetricCard**: KPI displays with trend indicators
- **ChartCard**: Interactive line charts with fl_chart
- **Sidebar**: Navigation with nested menu support

## 📊 Dashboard Components

### MetricCard - KPI Display
```dart
MetricCard(
  title: 'Total Revenue',
  value: '\$45,231.89',
  percentage: '+20.1%',
  trend: 'from last month',
  isPositive: true,
)
```

### ChartCard - Interactive Charts
```dart
ChartCard(
  title: 'Analytics Overview',
  timePeriods: ['7 days', '30 days', '90 days'],
  datasets: {
    '7 days': ChartDataSet(
      primaryData: [ChartDataPoint(label: 'Mon', value: 120)],
    ),
  },
)
```

## 🎨 Forui Integration

### Theme Access
```dart
// Colors and typography from Forui theme
color: context.theme.colors.primary
style: context.theme.typography.base.copyWith(fontWeight: FontWeight.w500)
```

### Component Usage
```dart
FCard.raw(/* ... */),
FButton(/* ... */),
FIcon(FIcons.dashboard),
```

## 🔧 Customization

### Replace Sample Data
```dart
// Update navigation in navigation_data.dart
static final List<NavigationItem> navMain = [
  NavigationItem(title: 'My Dashboard', icon: FIcons.home, url: '/dashboard'),
];

// Replace metrics in dashboard_page.dart
MetricCard(
  title: 'Active Users',
  value: '${myApiData.activeUsers}',
  percentage: '+${myApiData.userGrowth}%',
)
```

### Add New Dashboard Card
```dart
class CustomMetricCard extends StatelessWidget {
  Widget build(BuildContext context) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column([
          Text(title, style: context.theme.typography.sm),
          // Your custom content
        ]),
      ),
    );
  }
}
```

## 📱 Responsive Design

**Breakpoints:**
- **Mobile** (< 768px): Single column, drawer navigation
- **Tablet** (768px - 1200px): Two columns, collapsible sidebar
- **Desktop** (> 1200px): Three/four columns, full sidebar

## 🔗 Connect Real Data

### API Integration
```dart
class DashboardDataService {
  Future<List<MetricData>> getMetrics() async {
    final response = await http.get(Uri.parse('your-api/metrics'));
    return (json.decode(response.body) as List)
        .map((item) => MetricData.fromJson(item))
        .toList();
  }
}
```

### Real-Time Updates
```dart
Stream<MetricData> get metricsStream => 
    Stream.periodic(Duration(seconds: 30), (_) => fetchLatestMetrics());
```

## 📋 Customization Checklist

**Essential Changes:**
- [ ] Update navigation structure in `navigation_data.dart`
- [ ] Replace sample metrics with your KPI data
- [ ] Connect chart data to your analytics API
- [ ] Customize color scheme in theme provider
- [ ] Update app branding (title, icons, colors)
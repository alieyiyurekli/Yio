# YIO Recipe App

A modern Flutter food recipe mobile application with Material 3 design, inspired by Instagram and popular food recipe apps.

## Features

- 🏠 **Home Screen**: Browse trending recipes with beautiful card layouts
- 📖 **Recipe Details**: View detailed recipe information, ingredients, and step-by-step instructions
- 🤖 **AI Assistant**: Chat with an AI kitchen assistant for recipe suggestions
- 👤 **Profile Screen**: Manage your recipes, favorites, and achievements
- 🎨 **Modern UI**: Clean Material 3 design with custom theme
- 📱 **Responsive**: Optimized for various screen sizes

## Screenshots

### Main Features
- Story avatars with horizontal scroll
- Recipe feed with difficulty labels
- Chef information and category tags
- Like, comment, and share functionality
- Bottom navigation bar with 5 tabs

### Technologies Used

- **Flutter**: Latest stable version (3.x)
- **Material 3**: Modern design system
- **Google Fonts**: Poppins font family
- **Clean Architecture**: Organized folder structure

## Project Structure

```
lib/
 ├── main.dart
 ├── core/
 │    ├── theme/
 │    │    └── app_theme.dart
 │    └── constants/
 │         └── colors.dart
 │
 ├── models/
 │    └── recipe_model.dart
 │
 ├── widgets/
 │    ├── recipe_card.dart
 │    ├── story_avatar.dart
 │    ├── chat_bubble.dart
 │    └── ingredient_item.dart
 │
 ├── screens/
 │    ├── home/
 │    │    └── home_screen.dart
 │    │
 │    ├── recipe/
 │    │    └── recipe_detail_screen.dart
 │    │
 │    ├── ai/
 │    │    └── ai_assistant_screen.dart
 │    │
 │    └── profile/
 │         └── profile_screen.dart
 │
 └── navigation/
      └── bottom_navbar.dart
```

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd yio_recipe_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- `google_fonts: ^6.1.0` - Beautiful fonts
- `cached_network_image: ^3.3.0` - Efficient image loading
- `flutter_staggered_grid_view: ^0.7.0` - Grid layouts
- `provider: ^6.0.0` - State management
- `go_router: ^13.0.0` - Navigation
- `intl: ^0.19.0` - Internationalization

## Color Scheme

- **Primary**: `#FF7A45` (Orange)
- **Background**: `#F5F5F5` (Light Gray)
- **Card Background**: `#FFFFFF` (White)
- **Text Primary**: `#2D2D2D` (Dark Gray)

## Dummy Data

The app includes dummy data for:
- 8+ recipes with various cuisines
- 5+ chefs with avatars
- Categories: Healthy, Seafood, Vegan, American, Dessert, Breakfast, Thai, Salad
- Difficulty levels: Easy, Medium, Hard

## Screens

### 1. Home Screen
- YIO logo in AppBar
- Notification, Message, and AI Assistant icons
- Horizontal story carousel
- Trend/Following/New tabs
- Recipe feed with cards

### 2. Recipe Detail Screen
- Large hero image
- Chef information
- Time, Calories, and Difficulty stats
- Ingredients checklist
- Step-by-step instructions
- Save to favorites button

### 3. AI Assistant Screen
- ChatGPT-style interface
- Suggestion chips
- Real-time chat messages
- Input field with send button

### 4. Profile Screen
- User avatar and level badge
- Stats: Recipes, Followers, Following
- Achievement badges
- My Recipes / Favorites tabs
- Recipe grid layout (3 columns)

## Navigation

The app uses named routes:
- `/home` - Home screen
- `/recipeDetail` - Recipe detail screen
- `/aiAssistant` - AI assistant screen
- `/profile` - Profile screen

## Bottom Navigation Bar

1. **Home** - Browse recipes
2. **Search** - Search functionality (placeholder)
3. **Create** - Add new recipe (placeholder)
4. **Likes** - Liked recipes (placeholder)
5. **Profile** - User profile

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Author

YIO Recipe App - A modern Flutter application for food lovers.

---

**Note**: This app uses dummy data and placeholder images from Unsplash. For production use, replace with actual API endpoints and user authentication.

# BudgetBite screen guide

Each navigable route has a dedicated screen file. Edit the screen file first;
shared UI belongs in `lib/shared/widgets`, and data/business logic belongs in
`lib/state`, `lib/services`, or `lib/domain`.

## Routes

| Route | Screen file | What to edit |
| --- | --- | --- |
| `/login` | `lib/features/auth/login_screen.dart` | Sign-in form and actions |
| `/create-account` | `lib/features/auth/create_account_screen.dart` | Account creation form |
| `/discover` | `lib/features/discover/discover_screen.dart` | Search and recipe grid |
| `/plan` | `lib/features/plan/plan_screen.dart` | Grocery plan layout |
| `/budget` | `lib/features/budget/budget_screen.dart` | Budget book layout |
| `/saved` | `lib/features/saved/saved_screen.dart` | Saved recipes |
| `/preferences` | `lib/features/preferences/preferences_screen.dart` | Dietary preferences |
| `/location` | `lib/features/location/location_screen.dart` | Shopping location entry |
| `/account` | `lib/features/account/account_screen.dart` | Account center |

## Screen-specific components

Large screens are split into focused files so individual parts can be changed
without editing the whole page:

- Plan: `recipe_plan_card.dart`, `stores_card.dart`, `store_option.dart`,
  `location_confirmation.dart`, and `plan_links.dart`
- Budget: `budget_item_row.dart` and `total_line.dart`
- Discover: `welcome_panel.dart` and `hero_image.dart`

Routes are wired in `lib/routing/app_router.dart`. Keep route paths there and
keep screen-specific UI in the corresponding feature folder.

# AgriMarket Mobile App

## Team

| # | Name | ID |
|---|------|-----|
| 1 | Biruk Demissie | UGR/1666/15 |
| 2 | Bisart Alemayehu | UGR/0633/15 |
| 3 | Kaletsidik Ayalew | UGR/9300/15 |
| 4 | Khalid Abdifetah | URG/9210/15 |

## About the Project

**AgriMarket** is a Flutter mobile app that connects Ethiopian farmers and traders. Farmers can manage farms, list produce on a marketplace, and get crop recommendations, price forcast and AI-assisted advice. Traders browse and buy from the marketplace after their accounts are approved.

## Repository Note

We developed the full AgriMarket project (backend, AI, and mobile) together in one repository. The **mobile app was moved into this separate repo** so the submission is easier to review. Because of that split, **commit history here does not reflect our full development timeline**.

The **server and AI code** live in the main project repo:

**https://github.com/Bisruxa/AgriMarket.git**

Clone that repo to run the backend and use AI features with this app.

## Demo Login (for reviewers)

Use these credentials to try the app quickly:

| Role | Email | Password |
|------|--------|----------|
| **Farmer** | `imbisru@gmail.com` | `Bisru12345.` |
| **trader** | `trader@gmail.com` | `Bisru12345.` |

**Traders:** In production, new trader accounts must be **approved by an admin** before they can log in.

**For testing:** To keep review simple, we configure the system so **all accounts can be approved by admin**For this time only all users can simply enter the system with default value of verification status of APPROVED but in the real system for each trader admins will have the responsibility to approve them.

## Run the App

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. From this folder: `flutter pub get`
3. Start the backend from [AgriMarket](https://github.com/Bisruxa/AgriMarket.git) (see that repos README).
4. Run: `flutter run` ( since the )

# Recon map: OraRepot PPOB (Flutter mobile)

Scope: Consumer PPOB wallet shell — home balance, pulsa product pick, transaction history.
For: TIKN OraRepot mobile (brand/concept from orappob; layout from supplied design; structure from Agenin base-product patterns).
Date: 2026-11-14

## Sources

| # | source | URL / path | notes |
| --- | --- | --- | --- |
| 1 | Design screenshot | `replica/screens/design-home-pulse-history.png` | Home, Pulse, History mockups |
| 2 | orappob web | `/Applications/DEVELOPMENT/TIKN/orappob` | Brand, lime theme, PPOB catalog concept |
| 3 | Base mobile app | `/Applications/DEVELOPMENT/INDIVARAGROUP/Agenin/base-product/mobile-app` | Feature folders, home shell, beranda patterns (structure only) |
| 4 | Current Flutter app | `orarepot-mobile` | AppConfig, package name, demo catalog |

## Core loop

Agent/customer opens home, picks a service (e.g. Pulsa), enters a phone number, selects a denomination, continues to review/pay, later checks history.

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Beranda | bottom nav Home | Balance, quick actions, service grid | greeting, balance card, action circles, monthly stats, 8 service tiles, bottom nav | filled (seed) |
| S02 | Pulsa | tap Pulse/Pulsa on S01 | Pick number + denomination | app bar, phone field + provider chip, Pulse/Internet tabs, amount grid, Continue | empty number, selected amount |
| S03 | Riwayat | bottom nav History | Filtered transaction list | date from/to, summary chips, dated list, status icons | filled (seed), empty |
| S04 | Bantuan | bottom nav Customer | Support entry | stub | guest |
| S05 | Profil | bottom nav Profile | Account | stub guest CTA | guest |
| S06 | Review | Continue on S02 | Confirm before pay | bottom sheet rows + pay CTA | valid |

## Flows

```
F01 Pulsa top-up
    S01 -> S02 -> S06 -> payment handoff (stub)
    happy path clicks: ~5
    edge: number too short, no amount selected

F02 Browse history
    S03 set date range -> list by day
    edge: empty range

F03 Quick wallet actions
    S01 top-up / transfer / withdraw / scan (stub toasts until backend)
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| BalanceCard | gradient | loaded | S01 |
| QuickActionCircle | 4 icons | default | S01 |
| ServiceGridTile | 8 services | default | S01 |
| AmountCard | idle / selected | selected black fill | S02 |
| PrimaryButton | black / lime accent | default, disabled | S02, S06 |
| HistoryRow | success | filled | S03 |
| DateFilterField | from / to | filled | S03 |
| BottomNav | 4 tabs | active black | shell |

## Inferred data model

```
WalletSnapshot  balanceMinor, points, currency
                evidence: S01 balance card
                confidence: high (UI seed)

ServiceCategory  id, label, iconKind, route
                 evidence: S01 grid, orappob catalog kinds
                 confidence: high

ProductOption  name, faceValueMinor, sellPriceMinor, kind (pulsa|data)
               evidence: S02 cards
               confidence: high

Transaction  id, sn, createdAt, amountMinor, status (success|pending|failed), type
             evidence: S03 list
             confidence: high
```

Relationships: User 1-1 WalletSnapshot, User 1-n Transaction, ServiceCategory 1-n ProductOption.

## Feature matrix

See `features.csv`. Must: 8, should: 4, could: 2, skip: 2.

## Out of scope (cannot or should not be cloned)

- Live biller / provider APIs and settlement
- Provider-owned logos (XL mark shown as text chip only)
- Payment gateway credentials / QR generation
- Agenin agent-only modules (downline, stock, direct selling)

## Size

Screens 6, flows 3, entities 4. Hard parts: live catalog + payments. Size: **M** for UI shell; **L** with backend.

import '../models/wallpaper.dart';
import '../models/wallpaper_category.dart';

// ---------------------------------------------------------------------------
// Demo data only. Once your REST API is ready, replace these with a
// repository/service that fetches and decodes JSON into these same models —
// no screen or widget code needs to change.
// ---------------------------------------------------------------------------

const List<WallpaperCategory> sampleCategories = [
  WallpaperCategory(
    id: 1,
    name: 'Nature',
    totalWallpapers: 1200,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDg7TEpQlJ26cJtx0tgUTnSd7G_MjYyFHLY324SidwCcTYEwFGK5ZbDU3INMwuPCAfzEe1RacyKHYYv650Np8k9qvjIbY6_NJKDtggRUh7h-g7Vz4mJC5c8noqrSZRnsujHYfR2Jl4CG5O6wK3JqcZZCFjDgUyUiVz-E31MKLgtc_V0iEiePNiUuBlXlPWk64BWB27xVv3h0V8C7sHZ7tzui0PZld1aRvW7JqZJpsUiznzaGFJyGgylNw',
  ),
  WallpaperCategory(
    id: 2,
    name: 'Abstract',
    totalWallpapers: 842,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDrVBLpWasEmwZ2N0a2B_9f40myX_vEtSvatgngNmaUTmzune-DLzn42UOcI5e-m04OUwWcUQRdlGaB65nmd8fBCcET8p_NnJ_pg2nO2UyeSilPGWbnJdWCdaipz_0mdRAC_1C-z8YLOJXcKYjOW-Br0AnrruFXgeWSE0a3GkQ_PaB7qlGyNCfRXwJIspAt_YZyjiYcq_1Usd0VxwUpaXZP0Tlrs4cxGp8iuc6J_v6Ffk47X1ctvKdT_g',
  ),
  WallpaperCategory(
    id: 3,
    name: 'Architecture',
    totalWallpapers: 650,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAAFhmoYjfhaaZbdrWzLwOa4hmFE_esdLwrmEUnt4mN9X7JoajVVt4TWMGIRCVhEebUAix528H82OoKM86RlSLUMpUn8aacv4dO5Dh1lZfg0z3OAwxfcqIQGDu_TlSOHRwFiQ0GC0dbUXHWP0TxtcUvQrIb5NGENvIvveqI0IOWSLzyavz93SnFDUQWk2OMBl6eFY2T7rM0Wi_DZJFpRTur1c992OOCJrzobnhoW8x2W8Vj1TF5KVMyZA',
  ),
  WallpaperCategory(
    id: 4,
    name: 'Space',
    totalWallpapers: 420,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCekeucgvc8RldcF494mIulJF0TDgpSr-EActUkg_JXvjmgzJBdExhJpTWr7AmzGrExmd48CnrN-3zyRX1xrCeCafSIUWTm5qRl31XZfCM7UXAUD8jzNltXMbGcD_DTw_Nkcolehhn2nOyDoBpVPaovuUNPSB5uMR8KGI9fqJM2d_ad3t9ajRa3BHet1EyeGDn6TaZ1VmQ2i9eTV0Q-MWfTc69pV7gPyB0xjCTTTIupwQSNrep3ZjOONQ',
  ),
  WallpaperCategory(
    id: 5,
    name: 'Urban',
    totalWallpapers: 915,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCh0n-MjaJ5bUfskTENlUYdUCDxs92A8JaeFUwPKy420_ucWlS69Vzb4lbxadyvHZ_lpdu032WqpV-p2wikEYLXoqv-vElL1ma7hKBiglLtHBmuh6TiJVHpW8WG66DhInmT3RHmKaA56a8nkVm1RZ6hqQ6V0j5xkTPZ4BMT0ZIRPrw1Qrom_PkaoVQnZJGuxItArEtneA4-ZYO6JHS_j7Tj5EiBRFufnjn2naTkLec40M_75KwhCqqvEw',
  ),
  WallpaperCategory(
    id: 6,
    name: 'Monochrome',
    totalWallpapers: 310,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBDLCc74woIFZRzm2tuft7Ft9Verjx3KRw6GOFHCDdHicPOZDfoKpazcLRIpxaqLvGnaqdRbvlLTcX7L_eh-6kDfSVeLZa1jEiGHsUudgxATmF2PRdA5K4ZzOfaX51-DoRVwum2MkW_hV3E-iisJCgXazBWvgcl2TEN1OXa-lSFFd2vliHTouUasZ6fcc8Q-TqNUDglZ8g2csWco2ORQj_8rDGvb6VwAmBUJ_yHW-QxnDU-1_NaSfYEhg',
  ),
  WallpaperCategory(
    id: 7,
    name: '3D Render',
    totalWallpapers: 560,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCPf7oLX4mlxpvj2O5y2fOsmd5W2leNQcH3wAL0qvDXTNcMGH6hXmuYRnEl8HHOVSOi9JNeFT9EqGaAAxH_zv0SIPJMTBLR7Pr5K6W7JWsHk8Vx0G-_A5PrS9Zx49ojQwa12l2qJK57wMtm1s34JsKcHHRsYHX0lzg9cPUdNOVqas8r8Ng4GBrkfgCkYf7rdYGSXKWv0m8-Bc-dYfoLy2FNXRMuujWquy2e60GHIu3uZOHxGyMRkw5cWg',
  ),
  WallpaperCategory(
    id: 8,
    name: 'Minimalism',
    totalWallpapers: 1500,
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBBbgHDB3tlMV_Xf3Ll-I56zAym5oegZngmpngluV3GqGWDs2GtUBXQGAsm1IoBft77NnPhbdehRF70R2hpY7v-at9PyVTNi6aJA3-hcaqcrJjJj3F-UKKYRomPA6zb-K-p8hA5aKRNrJV2pxw_acEibFS-aewMSBne4v9WhtIFjImd8w8IYFNqgUvMiY7YG1XceBIENibKJrO5feY-4Tz7vFgwPkzII3nDEOes3t8yESKwoUsLcprU3g',
  ),
];

/// Individual wallpapers used to populate Home / Explore / Trending grids.
/// Reuses the category art above as placeholder imagery.
final List<Wallpaper> sampleWallpapers = [
  Wallpaper(
    id: 'w1',
    title: 'Alpine Lake at Golden Hour',
    category: 'Nature',
    resolution: '5K',
    imageUrl: sampleCategories[0].imageUrl,
  ),
  Wallpaper(
    id: 'w2',
    title: 'Liquid Silk Waves',
    category: 'Abstract',
    resolution: '4K',
    imageUrl: sampleCategories[1].imageUrl,
  ),
  Wallpaper(
    id: 'w3',
    title: 'Brutalist Curves',
    category: 'Architecture',
    resolution: '4K',
    imageUrl: sampleCategories[2].imageUrl,
  ),
  Wallpaper(
    id: 'w4',
    title: 'Crimson Nebula',
    category: 'Space',
    resolution: '8K',
    imageUrl: sampleCategories[3].imageUrl,
  ),
  Wallpaper(
    id: 'w5',
    title: 'Neon Tokyo Nights',
    category: 'Urban',
    resolution: '5K',
    imageUrl: sampleCategories[4].imageUrl,
  ),
  Wallpaper(
    id: 'w6',
    title: 'Staircase Study',
    category: 'Monochrome',
    resolution: '4K',
    imageUrl: sampleCategories[5].imageUrl,
  ),
  Wallpaper(
    id: 'w7',
    title: 'Floating Glass Spheres',
    category: '3D Render',
    resolution: '6K',
    imageUrl: sampleCategories[6].imageUrl,
  ),
  Wallpaper(
    id: 'w8',
    title: 'The Single Pebble',
    category: 'Minimalism',
    resolution: '4K',
    imageUrl: sampleCategories[7].imageUrl,
  ),
];

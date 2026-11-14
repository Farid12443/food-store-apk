# PROMPT LENGKAP: Tutorial Flutter FoodStore (Bab 7: Halaman Home Screen)

> **Cara pakai:** salin seluruh isi file ini ke AI (Claude, ChatGPT, dll). AI akan menghasilkan materi tutorial Bab 7 beserta kode yang sama persis atau sangat mirip dengan kode acuan di bawah. File ini mengikuti format prompt Bab 1 sampai 3 dan Bab 10 sampai 13.

---

## 1. PERAN

Kamu adalah instruktur Flutter berpengalaman yang menulis tutorial berbahasa Indonesia untuk pemula. Gaya bahasa santai tapi jelas, memakai kata "kalian" saat menyapa pembaca. Tutorial berbentuk langkah demi langkah, setiap langkah diikuti kode dan penjelasan singkat.

## 2. TUJUAN

Buat materi tutorial lengkap untuk **Bab 7** dari kursus "Membuat Aplikasi E-Commerce FoodStore dengan Flutter". Aplikasi ini terhubung ke backend **Laravel REST API** (sudah dibuat di kursus sebelumnya).

Cakupan materi:

| Bab | Judul | Isi |
|---|---|---|
| 7 | Halaman Home Screen | 4 materi: Membuat Remote Resource, Menampilkan Data Slider, Menampilkan Data Categories, Menampilkan Data Produk |

Hasil akhir bab: halaman Home menampilkan slider promo, daftar kategori (scroll horizontal), produk populer (scroll horizontal), dan produk terbaru (scroll vertikal), semua datanya dari API.

## 3. KONTEKS PROYEK

- Nama project: `flutter_foodstore`, nama aplikasi (title): `Food Store`
- State management: BLoC (`flutter_bloc`) dengan Cubit dan model state `freezed`
- HTTP client: Dio, hasil request dibungkus pola `Either` dari `either_dart` (`Left` = pesan error `String`, `Right` = data sukses)
- Navigasi: `go_router`
- Tema: warna utama oranye (`Colors.orange`), Material 3

**File yang sudah ada dari Bab 1 sampai 6 (jangan dibuat ulang, hanya dipakai):**

- `lib/core/constants/app_config.dart` (memakai `AppConfig.STORAGE_IMAGE` untuk URL gambar)
- `lib/core/utils/currency_helper.dart` (`CurrencyHelper.formatRupiah(double)`)
- `lib/core/utils/auth_interceptor.dart` (menerima `AuthBloc`)
- BLoC: `AuthBloc`, `ProfileBloc`, `OrderCubit`
- Resource: `AuthRemoteResource`, `ProfileRemoteResource`, `OrderRemoteResource` di `lib/resource/remote/`
- Model: `lib/resource/model/category_model.dart` (properti `name`, `slug`, `image`), `product_model.dart` (properti `title`, `slug`, `image`, `price`, `ratingsAvgRating`), `paging_model.dart` (properti `data`, `nextPageUrl`, ada `PagingModel.fromMap(map, converter)`)
- Halaman dashboard: `lib/page/dashboard/home_page.dart` (masih berisi teks "Home Page" dari Bab 2) dan `dashboard_page.dart`
- Route `/dashboard/home` sudah ada di `app_router.dart`

> Catatan untuk AI: `AppRouter` pada bab ini masih menerima dua parameter saja (`authBloc` dan `orderRemoteResource`). Jangan menambah parameter lain ke `AppRouter` dan jangan membuat route baru di bab ini.

**Endpoint backend yang dipakai (relatif terhadap `AppConfig.API_PATH`):**

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `public/sliders` | Daftar slider promo |
| GET | `public/categories` | Daftar kategori |
| GET | `public/categories/{slug}` | Detail kategori berdasarkan slug |
| GET | `public/products?page=&search=` | Produk terbaru dengan paginasi dan pencarian |
| GET | `public/products-popular` | Produk populer |
| GET | `public/products/{slug}` | Detail produk berdasarkan slug |

## 4. ATURAN OUTPUT

1. Tulis dalam **Bahasa Indonesia**.
2. Output dalam format **Markdown**, satu materi satu bagian (heading `##`), langkah memakai heading `###` ("Langkah 1 - ...").
3. **Kode wajib mengikuti kode acuan** di bagian 5: nama file, nama folder, nama class, nama variabel, nama method, path import, dan struktur kode harus sama. Boleh merapikan format, tidak boleh mengganti nama atau arsitektur.
4. Setiap blok kode diberi label bahasa (`dart`, `bash`) dan di atasnya tulis path file, contoh: `lib/page/dashboard/home_page.dart`.
5. Setelah blok kode penting, beri penjelasan per bagian (apa yang ditambahkan, fungsi tiap properti/method).
6. Jangan memakai em dash (tanda hubung panjang) di teks maupun kode. Gunakan tanda hubung biasa atau titik dua.
7. Jangan menambah fitur, package, atau bab di luar yang tercantum.
8. Gunakan kotak catatan (`>`) untuk peringatan penting.
9. Di akhir bab, tulis ringkasan 2 sampai 3 kalimat tentang apa yang sudah dicapai.
10. Untuk file yang berubah di beberapa materi (`main.dart`, `home_page.dart`), tampilkan **kode lengkap file** di materi yang mengubahnya mengikuti aturan bertahap di bagian 5.2, 5.3, dan 5.4, lalu jelaskan hanya bagian yang baru.
11. Nama method `fecthSlider` pada `SliderCubit` (ada typo) adalah nama asli dari kode acuan. **Jangan dikoreksi**, karena bab berikutnya memakai nama ini.
12. Semua folder komponen memakai nama `lib/core/components/` (pakai huruf "s") pada path import.

---

# 5. BAB 7: HALAMAN HOME SCREEN

**Pembuka bab:** halaman home adalah halaman pertama yang dilihat pengguna. Isinya tiga jenis data: slider promo, kategori, dan produk. Di bab ini semuanya diambil dari API dan ditampilkan lewat BLoC Cubit.

> Catatan: setiap kali selesai membuat file state `freezed` (slider, category, product_populer, product), jalankan perintah berikut di terminal project agar file `*.freezed.dart` ter-generate:
>
> `dart run build_runner build --delete-conflicting-outputs`

## 5.1 Membuat Remote Resource

**Pembuka:** karena halaman home memiliki tiga data yang ditampilkan (slider, product, dan kategori), dibuat satu remote resource yang menampung ketiganya. Seperti resource lainnya, dibuat dulu data model untuk JSON Serialization atau Data Mapping, yaitu mengubah JSON menjadi objek Dart dan sebaliknya.

### Langkah 1 - Membuat Data Model

Buat file `api_response.dart` di folder `lib/resource/model`.

`lib/resource/model/api_response.dart`

```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final rawData = json['data'];
    return ApiResponse(
      success: json['success'],
      message: json['message'],
      data: (rawData is List)
          ? rawData.map((item) => fromJsonT(item)).toList()
          : fromJsonT(rawData),
    );
  }
}
```

Penjelasan: `ApiResponse<T>` adalah pembungkus standar respons API (`success`, `message`, `data`). Method `fromJson` menerima fungsi converter `fromJsonT`. Jika `data` berupa list, tiap elemen diubah lewat converter dan hasilnya `List`. Jika bukan list, `data` diubah menjadi satu objek.

Buat file `slider_model.dart`.

`lib/resource/model/slider_model.dart`

```dart
import 'dart:convert';

class SliderModel {
  int? id;
  String? image;
  String? link;
  DateTime? createdAt;
  DateTime? updatedAt;

  SliderModel({
    this.id,
    this.image,
    this.link,
    this.createdAt,
    this.updatedAt,
  });

  factory SliderModel.fromJson(String str) =>
      SliderModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SliderModel.fromMap(Map<String, dynamic> json) => SliderModel(
        id: json["id"],
        image: json["image"],
        link: json["link"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "image": image,
        "link": link,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
```

### Langkah 2 - Membuat HomeRemoteResource

Buat file `home_remote_resource.dart` di folder `lib/resource/remote`. File ini mengambil data slider, category, dan product dalam satu class.

`lib/resource/remote/home_remote_resource.dart`

```dart
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_foodstore/resource/model/api_response.dart';
import 'package:flutter_foodstore/resource/model/category_model.dart';
import 'package:flutter_foodstore/resource/model/paging_model.dart';
import 'package:flutter_foodstore/resource/model/product_model.dart';
import 'package:flutter_foodstore/resource/model/slider_model.dart';

class HomeRemoteResource {
  final Dio dio;
  HomeRemoteResource(this.dio);

  Future<Either<String, List<SliderModel>>> fetchSliders() async {
    try {
      final response = await dio.get('public/sliders');
      if (response.statusCode == 200) {
        final apiResponse =
            ApiResponse.fromJson(response.data, SliderModel.fromMap);
        return Right(apiResponse.data);
      }
      return Left('Failed to fetch slider');
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await dio.get('public/categories');
      if (response.statusCode == 200) {
        final apiResponse =
            ApiResponse.fromJson(response.data, CategoryModel.fromMap);
        return Right(apiResponse.data);
      }
      return Left('Failed to fetch Category');
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, CategoryModel>> fetchCategoryBySlug(String slug) async {
    try {
      final response = await dio.get('public/categories/$slug');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        CategoryModel.fromMap,
      );
      if (response.statusCode == 200) {
        return Right(apiResponse.data);
      }
      return Left('Failed to fetch Product');
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, PagingModel<ProductModel>>> fetchProducts({
    int page = 0,
    String query = '',
  }) async {
    try {
      final response =
          await dio.get('public/products?page=$page&search=$query');
      final result =
          PagingModel.fromMap(response.data['data'], ProductModel.fromMap);
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<ProductModel>>> fetchProductsPopuler() async {
    try {
      final response = await dio.get('public/products-popular');
      final apiResponse =
          ApiResponse.fromJson(response.data, ProductModel.fromMap);
      return Right(apiResponse.data);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, ProductModel>> detailProduct(String slug) async {
    try {
      final response = await dio.get('public/products/$slug');
      final apiResponse =
          ApiResponse.fromJson(response.data, ProductModel.fromMap);
      return Right(apiResponse.data);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }
}
```

**Penjelasan wajib per bagian:**

1. **Import:** `dio` adalah HTTP client untuk API request (GET, POST, dll), lebih lengkap dibanding package `http` karena mendukung interceptor, request yang bisa dibatalkan, dan form data. `either_dart` membantu menangani operasi yang sukses (`Right`) atau gagal (`Left`), alternatif dari `try-catch` dengan pendekatan functional programming. Model yang diimpor: `ApiResponse` (struktur standar respons API), `CategoryModel` (data kategori), `PagingModel` (data paginasi untuk daftar produk berhalaman), `ProductModel` (data produk), `SliderModel` (data slider atau banner promo).
2. **Class `HomeRemoteResource`:** `final Dio dio` adalah Dependency Injection untuk instance Dio. Alasannya agar bisa di-mock saat testing atau diganti konfigurasi lain. Constructor menerima `Dio` sebagai parameter.
3. **Method-method API:**
   - `fetchSliders()`: GET `public/sliders`. Jika status 200, respons di-parse ke `ApiResponse` dengan converter `SliderModel.fromMap`. Hasil sukses `List<SliderModel>`, gagal berupa pesan error `String`.
   - `fetchCategories()`: GET `public/categories`, strukturnya sama dengan `fetchSliders()` tetapi memakai `CategoryModel`.
   - `fetchCategoryBySlug(String slug)`: ambil detail kategori berdasarkan slug (misal `public/categories/beverages`). Hasil sukses satu objek `CategoryModel`.
   - `fetchProducts({int page = 0, String query = ''})`: ambil produk dengan paginasi dan pencarian lewat `public/products?page=1&search=burger`. Hasil sukses `PagingModel<ProductModel>` (data produk dan info halaman).
   - `fetchProductsPopuler()`: ambil produk populer dari `public/products-popular`. Hasil sukses `List<ProductModel>`.
   - `detailProduct(String slug)`: ambil detail produk berdasarkan slug (misal `public/products/chicken-burger`). Hasil sukses satu objek `ProductModel`.

---

## 5.2 Menampilkan Data Slider

**Pembuka:** slider dipakai untuk menampilkan promo atau diskon produk. Sebelum membuat UI, dibuat dulu logika bisnis yang menghubungkan remote resource dengan UI memakai BLoC Cubit.

### Langkah 1 - Membuat BLoC Cubit

Klik kanan folder `lib/bloc`, pilih **Bloc: New Cubit**, beri nama `Slider`. Setelah ter-generate, ubah nama folder `cubit` menjadi `slider`. Hasilnya `lib/bloc/slider/slider_cubit.dart` dan `slider_state.dart`.

`lib/bloc/slider/slider_state.dart`

```dart
part of 'slider_cubit.dart';

@freezed
class SliderState with _$SliderState {
  const factory SliderState.initial() = _Initial;
  const factory SliderState.loading() = _Loading;
  const factory SliderState.loaded(List<SliderModel> sliders) = _Loaded;
  const factory SliderState.error(String message) = _Error;
}
```

Penjelasan state: `initial` (state awal), `loading` (saat memuat data), `loaded` (membawa `List<SliderModel>`), `error` (membawa pesan error).

`lib/bloc/slider/slider_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/slider_model.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'slider_state.dart';
part 'slider_cubit.freezed.dart';

class SliderCubit extends Cubit<SliderState> {
  final HomeRemoteResource homeRemoteResource;
  SliderCubit(this.homeRemoteResource) : super(SliderState.initial());

  fecthSlider() async {
    emit(SliderState.loading());
    try {
      final result = await homeRemoteResource.fetchSliders();
      result.fold(
        (error) => emit(SliderState.error(error)),
        (sliders) => emit(SliderState.loaded(sliders)),
      );
    } catch (e) {
      emit(SliderState.error(e.toString()));
    }
  }
}
```

Jalankan build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Langkah 2 - Implementasi di `main.dart`

Inisialisasi `HomeRemoteResource` dan `SliderCubit`. Kode lengkap `main.dart` pada tahap ini:

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foodstore/bloc/auth/auth_bloc.dart';
import 'package:flutter_foodstore/bloc/order/order_cubit.dart';
import 'package:flutter_foodstore/bloc/profile/profile_bloc.dart';
import 'package:flutter_foodstore/bloc/slider/slider_cubit.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/core/utils/auth_interceptor.dart';
import 'package:flutter_foodstore/resource/remote/auth_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/order_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/profile_remote_resource.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dio = Dio(BaseOptions(baseUrl: AppConfig.API_PATH));
  final homeRemoteResource = HomeRemoteResource(dio);
  final profileRemoteResource = ProfileRemoteResource(dio);
  final authRemoteResource = AuthRemoteResource(dio);
  final orderRemoteResource = OrderRemoteResource(dio);
  final authBloc = AuthBloc(authRemoteResource)
    ..add(AuthEvent.checkLoginStatus());
  final appRouter =
      AppRouter(authBloc: authBloc, orderRemoteResource: orderRemoteResource);
  dio.interceptors.add(AuthInterceptor(authBloc));
  runApp(MyApp(
      appRouter: appRouter,
      authBloc: authBloc,
      profileRemoteResource: profileRemoteResource,
      orderRemoteResource: orderRemoteResource,
      homeRemoteResource: homeRemoteResource));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  final AuthBloc authBloc;
  final ProfileRemoteResource profileRemoteResource;
  final OrderRemoteResource orderRemoteResource;
  final HomeRemoteResource homeRemoteResource;
  const MyApp({
    super.key,
    required this.appRouter,
    required this.authBloc,
    required this.profileRemoteResource,
    required this.orderRemoteResource,
    required this.homeRemoteResource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(
          create: (context) => ProfileBloc(profileRemoteResource),
        ),
        BlocProvider(
          create: (context) => OrderCubit(orderRemoteResource),
        ),
        BlocProvider(
          create: (context) => SliderCubit(homeRemoteResource)..fecthSlider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Food Store',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey.shade100,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
          useMaterial3: true,
        ),
        routerConfig: appRouter.router,
      ),
    );
  }
}
```

Penjelasan: `homeRemoteResource` dibuat dari instance `dio` yang sama dengan resource lain, lalu dikirim ke `MyApp`. `SliderCubit` didaftarkan di `MultiBlocProvider` dan langsung memanggil `fecthSlider()` sehingga data diambil saat aplikasi dibuka.

### Langkah 3 - Membuat UI Slider

Buka `lib/page/dashboard/home_page.dart`, ubah menjadi berikut.

`lib/page/dashboard/home_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/slider/slider_cubit.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/resource/model/slider_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSliderSection(),
        ],
      ),
    );
  }

  Widget _buildSliderSection() {
    return BlocBuilder<SliderCubit, SliderState>(
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => _buildLoadingIndicator(),
          loaded: (sliders) => _buildImageSlider(sliders),
          orElse: () => _buildErrorMessage("Failed to load sliders"),
        );
      },
    );
  }

  Widget _buildImageSlider(List<SliderModel> sliders) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Stack(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: sliders.length,
              itemBuilder: (context, index) {
                final slider = sliders[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    '${AppConfig.STORAGE_IMAGE}${slider.image}',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          _buildSliderNavigationButton(Icons.arrow_back_ios, () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }),
          _buildSliderNavigationButton(Icons.arrow_forward_ios, () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, alignRight: true)
        ],
      ),
    );
  }

  Widget _buildSliderNavigationButton(
    IconData icon,
    VoidCallback onPressed, {
    bool alignRight = false,
  }) {
    return Positioned(
      left: alignRight ? null : 8,
      right: alignRight ? 8 : null,
      top: 50,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildErrorMessage(String message) => Center(child: Text(message));

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());
}
```

**Penjelasan wajib per bagian:**

- **Import:** `flutter/material.dart` (UI), `flutter_bloc` (state management), `slider_cubit.dart`, `app_config.dart` (URL gambar), `slider_model.dart`.
- **`HomePage` sebagai `StatefulWidget`** karena memegang `PageController`. `dispose()` membersihkan `_pageController` dari memori.
- **`build`:** `SingleChildScrollView` agar halaman bisa di-scroll, `Column` dengan `spacing: 16` dan `CrossAxisAlignment.stretch`, isinya `_buildSliderSection()`.
- **`_buildSliderSection`:** `BlocBuilder<SliderCubit, SliderState>` dengan `maybeWhen`: `loading` menampilkan indikator, `loaded` menampilkan slider, `orElse` menampilkan pesan error.
- **`_buildImageSlider`:** `Stack` menumpuk tombol navigasi di atas `PageView.builder` (tinggi 150, sudut gambar membulat 16 lewat `ClipRRect`, gambar dari `AppConfig.STORAGE_IMAGE` ditambah `slider.image`).
- **`_buildSliderNavigationButton`:** tombol panah kiri dan kanan memakai `Positioned`. `alignRight` menentukan posisi, `previousPage` dan `nextPage` dengan durasi 300 ms dan `Curves.easeInOut`.

### Langkah 4 - Uji Coba

Jalankan project. Slider tampil di halaman home dan bisa digeser atau diganti dengan tombol panah.

---

## 5.3 Menampilkan Data Categories

**Pembuka:** kategori memberi tahu pengguna kategori makanan apa saja yang ada di aplikasi. Alurnya sama dengan slider: BLoC Cubit dulu, lalu UI.

### Langkah 1 - Membuat BLoC Cubit

Klik kanan `lib/bloc`, pilih **Bloc: New Cubit**, beri nama `Category`, lalu ubah folder `cubit` menjadi `category`.

`lib/bloc/category/category_state.dart`

```dart
part of 'category_cubit.dart';

@freezed
class CategoryState with _$CategoryState {
  const factory CategoryState.initial() = _Initial;
  const factory CategoryState.loading() = _Loading;
  const factory CategoryState.loaded(List<CategoryModel> categories) = _Loaded;
  const factory CategoryState.loadedCategoryBySlug(CategoryModel category) =
      _LoadedCategoryBySlug;
  const factory CategoryState.error(String message) = _Error;
}
```

Penjelasan state: `initial`, `loading`, `loaded` (list kategori), `loadedCategoryBySlug` (satu kategori berdasarkan slug), `error`.

`lib/bloc/category/category_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/category_model.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_state.dart';
part 'category_cubit.freezed.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final HomeRemoteResource homeRemoteResource;
  CategoryCubit(this.homeRemoteResource) : super(CategoryState.initial());

  fetchCategory() async {
    emit(CategoryState.loading());
    final result = await homeRemoteResource.fetchCategories();
    result.fold(
      (error) => emit(
        CategoryState.error(error.toString()),
      ),
      (categories) => emit(
        CategoryState.loaded(categories),
      ),
    );
  }

  fetchCategoryBySlug(String slug) async {
    emit(CategoryState.loading());
    final result = await homeRemoteResource.fetchCategoryBySlug(slug);
    result.fold(
      (error) => emit(
        CategoryState.error(error.toString()),
      ),
      (product) => emit(
        CategoryState.loadedCategoryBySlug(product),
      ),
    );
  }
}
```

Jalankan build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Langkah 2 - Implementasi di `main.dart`

> Catatan untuk AI: tulis kode lengkap `main.dart` yang sama dengan materi 5.2, dengan dua tambahan: import `package:flutter_foodstore/bloc/category/category_cubit.dart` (diurutkan setelah import `auth_bloc.dart`) dan provider berikut sebagai elemen terakhir `providers` di `MultiBlocProvider`.

```dart
BlocProvider(
  create: (context) =>
      CategoryCubit(homeRemoteResource)..fetchCategory(),
),
```

### Langkah 3 - Membuat UI Category

Sebelum halaman utama, dibuat komponen kartu untuk satu kategori. Buat file `category_card.dart` di folder `lib/core/components`.

`lib/core/components/category_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/resource/model/category_model.dart';
import 'package:go_router/go_router.dart';

class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => context.push('/productByCategory', extra: widget.category),
        child: Container(
          width: 85,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    '${AppConfig.STORAGE_IMAGE}${widget.category.image}',
                    fit: BoxFit.fill,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.category.name.toString(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Penjelasan wajib:**

- Import: `material.dart`, `app_config.dart` (URL dasar gambar), `category_model.dart`, `go_router.dart` (navigasi).
- `CategoryCard` menerima properti `CategoryModel category`.
- UI berupa `Card` dengan sudut membulat 12 dan `elevation: 1`. `InkWell` memberi efek ripple, saat di-tap membuka `/productByCategory` sambil membawa data kategori lewat `extra`.
- Konten: `Container` lebar 85, berisi `Column` dengan gambar (`Expanded`, `ClipRRect` sudut 8, `BoxFit.fill`) dan nama kategori (ukuran 14, tebal, rata tengah).

> Catatan: route `/productByCategory` dibuat di Bab 8. Di bab ini kartu belum bisa dibuka halaman tujuannya, itu normal.

Sekarang tampilkan di `home_page.dart`. Kode lengkap tahap ini:

> Catatan untuk AI: tulis kode lengkap `home_page.dart` versi bertahap, dibentuk dari versi akhir di materi 5.4 dengan aturan: hapus import `product_cubit.dart`, `product_populer_cubit.dart`, `product_card.dart`, dan `go_router.dart`; hapus dua pemanggilan `_buildProductSection(...)` di `build`; hapus method `_buildProductSection`, `_buildSectionHeader`, dan `_navigateToAllProducts`. Sisakan `_buildSliderSection()` dan `_buildCategorySection()` di `children`, serta `_buildEmptyMessage()`. Tambahkan import `category_cubit.dart` dan `category_card.dart`.

Bagian baru yang perlu dijelaskan:

```dart
Widget _buildCategorySection() {
  return BlocBuilder<CategoryCubit, CategoryState>(
    builder: (context, state) {
      return state.maybeWhen(
        loading: () => _buildLoadingIndicator(),
        loaded: (categories) => categories.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryCard(
                        category: category,
                      );
                    },
                  ),
                ),
              )
            : _buildEmptyMessage(),
        orElse: () => _buildErrorMessage("Failed to load categories"),
      );
    },
  );
}
```

Penjelasan: `BlocBuilder<CategoryCubit, CategoryState>`: saat `loading` tampil indikator, saat `loaded` dan datanya tidak kosong tampil `ListView.builder` horizontal setinggi 120 berisi `CategoryCard`, jika kosong tampil "Tidak ada data tersedia", selain itu pesan error "Failed to load categories".

### Langkah 4 - Uji Coba

Jalankan ulang project. Di bawah slider muncul daftar kategori yang bisa digeser ke samping.

---

## 5.4 Menampilkan Data Produk

**Pembuka:** ada dua tampilan produk: produk populer (scroll horizontal, seperti kategori) dan produk terbaru (scroll vertikal).

### Langkah 1 - Membuat Komponen Card Product

Kartu ini dipakai untuk produk populer maupun terbaru, dan memiliki tombol aksi untuk menambah ke keranjang (logikanya dibuat di bab Cart). Buat file `product_card.dart` di folder `lib/core/components`.

`lib/core/components/product_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/core/utils/currency_helper.dart';
import 'package:flutter_foodstore/resource/model/product_model.dart';
import 'package:go_router/go_router.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool isPopular;
  const ProductCard({
    super.key,
    required this.product,
    required this.isPopular,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return widget.isPopular
        ? _buildProductCardPopular(widget.product)
        : _buildProductCardNew(widget.product);
  }

  /// Widget untuk Card Product New
  Widget _buildProductCardNew(ProductModel product) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _navigateToDetailProduct(product),
        child: SizedBox(
          width: 180,
          child: Stack(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12.0)),
                      child: Image.network(
                          '${AppConfig.STORAGE_IMAGE}${product.image}',
                          fit: BoxFit.cover,
                          width: 150),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyHelper.formatRupiah(
                            product.price?.toDouble() ?? 0),
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            product.ratingsAvgRating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            Positioned(right: 10, bottom: 10, child: _addToCartButton(product))
          ]),
        ),
      ),
    );
  }

  /// Widget untuk Card Product Popular
  Widget _buildProductCardPopular(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => _navigateToDetailProduct(product),
          child: SizedBox(
            width: 180,
            child: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child: Image.network(
                          '${AppConfig.STORAGE_IMAGE}${product.image}',
                          fit: BoxFit.cover,
                          width: double.infinity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyHelper.formatRupiah(
                              product.price?.toDouble() ?? 0),
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(
                              product.ratingsAvgRating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(right: 2, bottom: 2, child: _addToCartButton(product))
            ]),
          ),
        ),
      ),
    );
  }

  /// Tombol Add to Cart
  Widget _addToCartButton(ProductModel product) {
    return IconButton.filledTonal(
      onPressed: () {
        // Add product to cart
      },
      icon: const Icon(
        Icons.add_shopping_cart_rounded,
        color: Colors.white,
      ),
    );
  }

  /// Navigasi ke Detail Product
  void _navigateToDetailProduct(ProductModel product) {
    context.push('/detailProduct/${product.slug}');
  }
}
```

**Penjelasan wajib:**

- Import: `app_config.dart` (URL gambar), `currency_helper.dart` (format rupiah), `product_model.dart`, `go_router.dart`.
- `ProductCard` menerima `ProductModel product` dan `bool isPopular`. `isPopular` menentukan tampilan: `true` memakai `_buildProductCardPopular`, `false` memakai `_buildProductCardNew`.
- `_buildProductCardNew`: kartu horizontal (`Row`) berisi gambar di kiri dan teks di kanan (judul, harga berwarna hijau, rating bintang).
- `_buildProductCardPopular`: kartu vertikal (`Column`) lebar 180 dengan gambar di atas (sudut atas membulat) dan teks di bawah.
- `_addToCartButton`: tombol `IconButton.filledTonal` berikon keranjang. Isi `onPressed` masih kosong (komentar `// Add product to cart`), akan diisi di bab Cart.
- `_navigateToDetailProduct`: membuka `/detailProduct/${product.slug}` dengan membawa slug produk.

> Catatan: route `/detailProduct/:slug` dibuat di Bab 8.

### Langkah 2 - Membuat BLoC Cubit Product Populer

Klik kanan `lib/bloc`, pilih **Bloc: New Cubit**, beri nama `ProductPopuler`, ubah folder menjadi `product_populer`.

`lib/bloc/product_populer/product_populer_state.dart`

```dart
part of 'product_populer_cubit.dart';

@freezed
class ProductPopulerState with _$ProductPopulerState {
  const factory ProductPopulerState.initial() = _Initial;
  const factory ProductPopulerState.loading() = _Loading;
  const factory ProductPopulerState.loadedProductPopuler(
      List<ProductModel> products) = _LoadedProductPopuler;
  const factory ProductPopulerState.error(String message) = _Error;
}
```

`lib/bloc/product_populer/product_populer_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/product_model.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_populer_state.dart';
part 'product_populer_cubit.freezed.dart';

class ProductPopulerCubit extends Cubit<ProductPopulerState> {
  final HomeRemoteResource homeRemoteResource;
  ProductPopulerCubit(this.homeRemoteResource)
      : super(ProductPopulerState.initial());

  fetchProductPopuler() async {
    emit(ProductPopulerState.loading());
    final result = await homeRemoteResource.fetchProductsPopuler();
    result.fold(
      (error) => emit(ProductPopulerState.error(error)),
      (products) => emit(ProductPopulerState.loadedProductPopuler(products)),
    );
  }
}
```

### Langkah 3 - Membuat BLoC Cubit Product New

Klik kanan `lib/bloc`, pilih **Bloc: New Cubit**, beri nama `Product`, ubah folder menjadi `product`.

`lib/bloc/product/product_state.dart`

```dart
part of 'product_cubit.dart';

@freezed
class ProductState with _$ProductState {
  const factory ProductState.initial() = _Initial;
  const factory ProductState.loading() = _Loading;
  const factory ProductState.loadedProduct(List<ProductModel> products,
      {required bool hasMore}) = _LoadedProduct;
  const factory ProductState.loadedDetailProduct(ProductModel product) =
      _LoadedDetailProduct;
  const factory ProductState.error(String message) = _Error;
}
```

`lib/bloc/product/product_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/product_model.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_state.dart';
part 'product_cubit.freezed.dart';

class ProductCubit extends Cubit<ProductState> {
  final HomeRemoteResource homeRemoteResource;
  ProductCubit(this.homeRemoteResource) : super(ProductState.initial());

  int _currentPage = 1;
  bool _hasMore = true;
  final List<ProductModel> _products = [];

  Future<void> fetchProduct({bool isRefresh = false, String query = ''}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
      emit(ProductState.loading());
    }

    final result = await homeRemoteResource.fetchProducts(
      page: _currentPage,
      query: query,
    );
    result.fold(
      (error) => emit(ProductState.error(error)),
      (paging) {
        if (_hasMore) {
          _hasMore = paging.nextPageUrl != null;
          _products.addAll(paging.data as List<ProductModel>);
          _currentPage++;
        }
        emit(ProductState.loadedProduct(
          List.from(_products),
          hasMore: _hasMore,
        ));
      },
    );
  }

  Future<void> detailProduct(String slug) async {
    emit(ProductState.loading());
    final result = await homeRemoteResource.detailProduct(slug);
    result.fold(
      (error) => emit(ProductState.error(error)),
      (product) => emit(ProductState.loadedDetailProduct(product)),
    );
  }
}
```

Jalankan build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Penjelasan wajib:**

- `ProductPopulerCubit.fetchProductPopuler()` memanggil `fetchProductsPopuler()` lalu mengeluarkan state `loadedProductPopuler` atau `error`.
- `ProductCubit` menyimpan `_currentPage`, `_hasMore`, dan daftar `_products` untuk paginasi. `fetchProduct({isRefresh, query})`: jika `isRefresh` true, halaman direset ke 1 dan daftar dikosongkan. Hasil tiap halaman ditambahkan ke `_products`, `_hasMore` bernilai false jika `nextPageUrl` kosong. Parameter `query` dipakai untuk pencarian.
- `detailProduct(slug)` mengeluarkan state `loadedDetailProduct` (dipakai di Bab 8).

### Langkah 4 - Implementasi di `main.dart`

Kode lengkap `main.dart` final bab ini:

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foodstore/bloc/auth/auth_bloc.dart';
import 'package:flutter_foodstore/bloc/category/category_cubit.dart';
import 'package:flutter_foodstore/bloc/order/order_cubit.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/bloc/product_populer/product_populer_cubit.dart';
import 'package:flutter_foodstore/bloc/profile/profile_bloc.dart';
import 'package:flutter_foodstore/bloc/slider/slider_cubit.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/core/utils/auth_interceptor.dart';
import 'package:flutter_foodstore/resource/remote/auth_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/order_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/profile_remote_resource.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dio = Dio(BaseOptions(baseUrl: AppConfig.API_PATH));
  final homeRemoteResource = HomeRemoteResource(dio);
  final profileRemoteResource = ProfileRemoteResource(dio);
  final authRemoteResource = AuthRemoteResource(dio);
  final orderRemoteResource = OrderRemoteResource(dio);
  final authBloc = AuthBloc(authRemoteResource)
    ..add(AuthEvent.checkLoginStatus());
  final appRouter =
      AppRouter(authBloc: authBloc, orderRemoteResource: orderRemoteResource);
  dio.interceptors.add(AuthInterceptor(authBloc));
  runApp(MyApp(
      appRouter: appRouter,
      authBloc: authBloc,
      profileRemoteResource: profileRemoteResource,
      orderRemoteResource: orderRemoteResource,
      homeRemoteResource: homeRemoteResource));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  final AuthBloc authBloc;
  final ProfileRemoteResource profileRemoteResource;
  final OrderRemoteResource orderRemoteResource;
  final HomeRemoteResource homeRemoteResource;
  const MyApp({
    super.key,
    required this.appRouter,
    required this.authBloc,
    required this.profileRemoteResource,
    required this.orderRemoteResource,
    required this.homeRemoteResource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(
          create: (context) => ProfileBloc(profileRemoteResource),
        ),
        BlocProvider(
          create: (context) => OrderCubit(orderRemoteResource),
        ),
        BlocProvider(
          create: (context) => SliderCubit(homeRemoteResource)..fecthSlider(),
        ),
        BlocProvider(
          create: (context) =>
              CategoryCubit(homeRemoteResource)..fetchCategory(),
        ),
        BlocProvider(
          create: (_) => ProductCubit(homeRemoteResource)..fetchProduct(),
        ),
        BlocProvider(
          create: (_) =>
              ProductPopulerCubit(homeRemoteResource)..fetchProductPopuler(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Food Store',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey.shade100,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
          useMaterial3: true,
        ),
        routerConfig: appRouter.router,
      ),
    );
  }
}
```

Penjelasan: dua provider baru, `ProductCubit` (memanggil `fetchProduct()`) dan `ProductPopulerCubit` (memanggil `fetchProductPopuler()`), beserta import-nya.

### Langkah 5 - Menampilkan Data di Home Page

Kode lengkap versi akhir `home_page.dart`:

`lib/page/dashboard/home_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/category/category_cubit.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/bloc/product_populer/product_populer_cubit.dart';
import 'package:flutter_foodstore/bloc/slider/slider_cubit.dart';
import 'package:flutter_foodstore/core/components/category_card.dart';
import 'package:flutter_foodstore/core/components/product_card.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/resource/model/slider_model.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSliderSection(),
          _buildCategorySection(),
          _buildProductSection(
            title: "Product Popular",
            icon: Icons.shopping_bag_outlined,
            cubit: BlocBuilder<ProductPopulerCubit, ProductPopulerState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading: () => _buildLoadingIndicator(),
                  loadedProductPopuler: (products) => products.isNotEmpty
                      ? SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            itemBuilder: (BuildContext context, int index) {
                              final product = products[index];
                              return ProductCard(
                                product: product,
                                isPopular: true,
                              );
                            },
                          ),
                        )
                      : _buildEmptyMessage(),
                  orElse: () =>
                      _buildErrorMessage("Failed to load popular products"),
                );
              },
            ),
          ),
          _buildProductSection(
            title: "Product Terbaru",
            icon: Icons.shopping_bag_outlined,
            cubit: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading: () => _buildLoadingIndicator(),
                  loadedProduct: (products, hasMore) => products.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              isPopular: false,
                            );
                          },
                        )
                      : _buildEmptyMessage(),
                  orElse: () =>
                      _buildErrorMessage("Failed to load latest products"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required IconData icon,
    required Widget cubit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: _buildSectionHeader(title, icon),
          ),
          cubit,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 4),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
          ],
        ),
        GestureDetector(
          onTap: () => _navigateToAllProducts(),
          child: Text(
            'Lihat Lainnya',
            style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => _buildLoadingIndicator(),
          loaded: (categories) => categories.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return CategoryCard(
                          category: category,
                        );
                      },
                    ),
                  ),
                )
              : _buildEmptyMessage(),
          orElse: () => _buildErrorMessage("Failed to load categories"),
        );
      },
    );
  }

  Widget _buildSliderSection() {
    return BlocBuilder<SliderCubit, SliderState>(
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => _buildLoadingIndicator(),
          loaded: (sliders) => _buildImageSlider(sliders),
          orElse: () => _buildErrorMessage("Failed to load sliders"),
        );
      },
    );
  }

  Widget _buildImageSlider(List<SliderModel> sliders) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Stack(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: sliders.length,
              itemBuilder: (context, index) {
                final slider = sliders[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    '${AppConfig.STORAGE_IMAGE}${slider.image}',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          _buildSliderNavigationButton(Icons.arrow_back_ios, () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }),
          _buildSliderNavigationButton(Icons.arrow_forward_ios, () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, alignRight: true)
        ],
      ),
    );
  }

  Widget _buildSliderNavigationButton(
    IconData icon,
    VoidCallback onPressed, {
    bool alignRight = false,
  }) {
    return Positioned(
      left: alignRight ? null : 8,
      right: alignRight ? 8 : null,
      top: 50,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildErrorMessage(String message) => Center(child: Text(message));

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildEmptyMessage() =>
      const Center(child: Text("Tidak ada data tersedia"));

  void _navigateToAllProducts() {
    context.push('/allProducts');
  }
}
```

**Penjelasan wajib (bagian baru):**

- Import baru: `product_cubit.dart`, `product_populer_cubit.dart`, `product_card.dart`, dan `go_router.dart`.
- `build` sekarang berisi empat bagian berurutan: slider, kategori, produk populer, produk terbaru.
- `_buildProductSection`: widget reusable dengan parameter `title`, `icon`, dan `cubit` (widget `BlocBuilder`). Terdiri dari header dan isi.
- `_buildSectionHeader`: judul seksi dengan ikon di kiri dan teks "Lihat Lainnya" (oranye, tebal) di kanan yang memanggil `_navigateToAllProducts()`.
- Produk populer: `BlocBuilder<ProductPopulerCubit, ProductPopulerState>`, daftar horizontal (`SizedBox` tinggi 200, `ProductCard(isPopular: true)`).
- Produk terbaru: `BlocBuilder<ProductCubit, ProductState>`, `ListView.builder` dengan `shrinkWrap: true` dan `NeverScrollableScrollPhysics` supaya ikut scroll halaman utama (`ProductCard(isPopular: false)`).
- `_buildEmptyMessage`: pesan "Tidak ada data tersedia" jika data kosong.
- `_navigateToAllProducts`: membuka `/allProducts` (route dibuat di Bab 8).

### Langkah 6 - Uji Coba

Jalankan ulang project. Halaman home menampilkan slider, kategori, "Product Popular" (scroll ke samping), dan "Product Terbaru" (daftar ke bawah).

**Ringkasan Bab 7 (tulis di akhir bab):** pembaca sudah membuat `HomeRemoteResource` dengan model `ApiResponse` dan `SliderModel`, empat Cubit (slider, category, product populer, product), komponen `CategoryCard` dan `ProductCard`, serta halaman home yang menampilkan slider, kategori, produk populer, dan produk terbaru dari API.

---

# 6. CHECKLIST HASIL AKHIR (WAJIB DICEK AI SEBELUM MENJAWAB)

File baru atau berubah setelah Bab 7 selesai:

```text
flutter_foodstore/
  lib/
    bloc/
      category/
        category_cubit.dart
        category_state.dart
      product/
        product_cubit.dart
        product_state.dart
      product_populer/
        product_populer_cubit.dart
        product_populer_state.dart
      slider/
        slider_cubit.dart
        slider_state.dart
    core/
      components/
        category_card.dart
        product_card.dart
    page/
      dashboard/
        home_page.dart
    resource/
      model/
        api_response.dart
        slider_model.dart
      remote/
        home_remote_resource.dart
    main.dart
```

Pastikan:

- [ ] Semua 4 materi ada dan urutannya benar.
- [ ] Nama file, class, variabel, dan path import sama persis dengan kode acuan (termasuk `fecthSlider` dan folder `core/components`).
- [ ] `main.dart` dan `home_page.dart` ditampilkan lengkap di tiap materi yang mengubahnya, mengikuti aturan versi bertahap.
- [ ] `AppRouter` tetap hanya menerima `authBloc` dan `orderRemoteResource`; tidak ada route baru.
- [ ] Perintah `dart run build_runner build --delete-conflicting-outputs` disebut setiap selesai membuat state `freezed`.
- [ ] Tidak ada em dash di seluruh teks dan kode.
- [ ] Bab ditutup dengan ringkasan singkat.
- [ ] Tidak ada fitur atau package tambahan di luar daftar.

> Catatan untuk AI: tombol add to cart pada `ProductCard` sengaja masih kosong, dan route `/allProducts`, `/detailProduct/:slug`, `/productByCategory` baru dibuat di Bab 8. Jangan ditambahkan di bab ini.
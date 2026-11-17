# PROMPT LENGKAP: Tutorial Flutter FoodStore (Bab 10: Halaman Checkout)

> **Cara pakai:** salin seluruh isi file ini ke AI (Claude, ChatGPT, dll). AI akan menghasilkan materi tutorial Bab 10 beserta kode yang sama persis atau sangat mirip dengan kode acuan di bawah. File ini mengikuti format prompt Bab 1 sampai 3 dan Bab 7 sampai 9.

---

## 1. PERAN

Kamu adalah instruktur Flutter berpengalaman yang menulis tutorial berbahasa Indonesia untuk pemula. Gaya bahasa santai tapi jelas, memakai kata "kalian" saat menyapa pembaca. Tutorial berbentuk langkah demi langkah, setiap langkah diikuti kode dan penjelasan singkat.

## 2. TUJUAN

Buat materi tutorial lengkap untuk **Bab 10** dari kursus "Membuat Aplikasi E-Commerce FoodStore dengan Flutter". Aplikasi ini terhubung ke backend **Laravel REST API** (sudah dibuat di kursus sebelumnya). Bab 1 sampai 9 sudah selesai (instalasi, navigasi, service API, autentikasi, profil, orders, home, product, cart).

Cakupan materi:

| Bab | Judul | Isi |
|---|---|---|
| 10 | Halaman Checkout | 7 materi: Membuat Checkout Remote Resource, Membuat BLoC Cubit, Implementasi CheckoutRemoteResource, Implementasi BLoC dan Navigasi, Membuat Tampilan Search Location, Menghitung Biaya Ongkos Kirim, Membuat Proses Checkout |

Hasil akhir bab: dari halaman cart, pengguna membuka halaman checkout, mencari lokasi tujuan, mengisi alamat, memilih ekspedisi dan layanan, melihat ongkos kirim dan total, lalu menekan tombol bayar yang membuka pembayaran Midtrans dan setelah itu halaman detail order.

## 3. KONTEKS PROYEK

- Nama project: `flutter_foodstore`, nama aplikasi (title): `Food Store`
- State management: BLoC (`flutter_bloc`) dengan Cubit dan model state `freezed`
- HTTP client: Dio, dibungkus pola `Either` dari `either_dart` (`Left` = pesan error `String`, `Right` = data sukses)
- Navigasi: `go_router` dengan `ShellRoute` untuk dashboard
- Tema: warna utama oranye (`Colors.orange`), Material 3
- Backend: Laravel REST API. Ongkos kirim memakai RajaOngkir, pembayaran memakai Midtrans (Snap).

**File yang sudah ada dari Bab 1 sampai 9 (jangan dibuat ulang, hanya dipakai):**

- BLoC: `AuthBloc` (`lib/bloc/auth/auth_bloc.dart`, event `AuthEvent.checkLoginStatus()`, state `Authenticated`), `CartBloc` (event `CartEvent.fetchCart()`), `CategoryCubit`, `OrderCubit`, `ProductCubit`, `ProductPopulerCubit`, `ProfileBloc` (event `ProfileEvent.loadProfile()`), `SliderCubit`, `ReviewProductCubit`
- Resource: `AuthRemoteResource`, `CartRemoteResource`, `HomeRemoteResource`, `OrderRemoteResource`, `ProfileRemoteResource` di `lib/resource/remote/`
- Core: `lib/core/constants/app_config.dart`, `lib/core/utils/auth_interceptor.dart` (menerima `AuthBloc`), `lib/core/utils/currency_helper.dart` (`CurrencyHelper.formatRupiah(double)`), `lib/core/components/product_card.dart`, `category_card.dart`, `cart_card.dart`
- Halaman: `login_page.dart`, `register_page.dart`, halaman dashboard (home, order, cart, profile), `midtrans_payment_page.dart`, `order_detail_page.dart`, `all_product_page.dart`, `detail_product_page.dart`, `product_by_category_page.dart`
- `CartPage` dari Bab 9 sudah memiliki tombol "Proceed to Checkout" yang membuka `/checkout?totalPrice=...&totalWeight=...` (route-nya dibuat di bab ini)
- `lib/app_router.dart` hasil Bab 9 (menerima `authBloc`, `orderRemoteResource`, `homeRemoteResource`) dan `lib/main.dart` hasil Bab 9

**Endpoint backend yang dipakai di Bab 10 (relatif terhadap `AppConfig.API_PATH`):**

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `public/search-destination?search=...` | Mencari lokasi tujuan, mengembalikan list lokasi |
| POST | `public/check-ongkir` | Body: `destination`, `weight`, `courier`. Mengembalikan list layanan dan biaya |
| POST | `public/checkout` | Membuat transaksi, respons berisi `data.snap_token` |

## 4. ATURAN OUTPUT

1. Tulis dalam **Bahasa Indonesia**.
2. Output dalam format **Markdown**, satu materi satu bagian (heading `##`), langkah memakai heading `###` ("Langkah 1 - ...").
3. **Kode wajib mengikuti kode acuan** di bagian 5: nama file, nama folder, nama class, nama variabel, nama method, path import, dan struktur kode harus sama. Boleh merapikan format, tidak boleh mengganti nama atau arsitektur.
4. Setiap blok kode diberi label bahasa (`dart`, `bash`) dan di atasnya tulis path file, contoh: `lib/page/checkout/checkout_page.dart`.
5. Setelah blok kode penting, beri penjelasan per bagian (apa yang ditambahkan, fungsi tiap properti/method).
6. Jangan memakai em dash (tanda hubung panjang) di teks maupun kode. Gunakan tanda hubung biasa atau titik dua.
7. Jangan menambah fitur, package, atau bab di luar yang tercantum.
8. Gunakan kotak catatan (`>`) untuk peringatan penting.
9. Di akhir bab, tulis ringkasan 2 sampai 3 kalimat tentang apa yang sudah dicapai.
10. Untuk file yang berubah di beberapa materi (`checkout_page.dart`, `app_router.dart`, `main.dart`), tampilkan **kode lengkap file** di setiap materi yang mengubahnya, lalu jelaskan hanya bagian yang baru. Aturan pembentukan versi bertahap `checkout_page.dart` ada di materi 5.5 dan 5.6 (dibentuk dari versi akhir di materi 5.7).
11. Nama method `fecthSlider` pada `SliderCubit` (ada typo) adalah nama asli dari Bab 7. **Jangan dikoreksi.**
12. Semua folder komponen memakai nama `lib/core/components/` (pakai huruf "s") pada path import.
13. Setiap kali selesai membuat file `freezed`, sebut perintah `dart run build_runner build --delete-conflicting-outputs`.

---

# 5. BAB 10: HALAMAN CHECKOUT

**Pembuka bab:** setelah selesai membuat cart, langkah berikutnya adalah checkout. Di halaman checkout pengguna memilih lokasi tujuan, mengisi alamat, memilih ekspedisi, melihat ongkos kirim, lalu lanjut ke pembayaran Midtrans.

## 5.1 Membuat Checkout Remote Resource

**Pembuka:** seperti biasa, sebelum membuat remote resource kita membuat data model untuk merepresentasikan hasil API JSON.

### Langkah 1 - Buat `location_model.dart`

`lib/resource/model/location_model.dart`

```dart
import 'dart:convert';

class LocationModel {
  final int? id;
  final String? label;
  final String? provinceName;
  final String? cityName;
  final String? districtName;
  final String? subdistrictName;
  final String? zipCode;

  LocationModel({
    this.id,
    this.label,
    this.provinceName,
    this.cityName,
    this.districtName,
    this.subdistrictName,
    this.zipCode,
  });

  factory LocationModel.fromJson(String str) =>
      LocationModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory LocationModel.fromMap(Map<String, dynamic> json) => LocationModel(
        id: json["id"],
        label: json["label"],
        provinceName: json["province_name"],
        cityName: json["city_name"],
        districtName: json["district_name"],
        subdistrictName: json["subdistrict_name"],
        zipCode: json["zip_code"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "label": label,
        "province_name": provinceName,
        "city_name": cityName,
        "district_name": districtName,
        "subdistrict_name": subdistrictName,
        "zip_code": zipCode,
      };
}
```

Penjelasan: model ini menyimpan hasil pencarian lokasi tujuan. Semua properti `final` dan nullable. `fromMap` memetakan key JSON snake_case dari API ke properti camelCase.

### Langkah 2 - Buat `shipping_cost_model.dart`

`lib/resource/model/shipping_cost_model.dart`

```dart
import 'dart:convert';

class ShippingCostModel {
  final String? name;
  final String? code;
  final String? service;
  final String? description;
  final int? cost;
  final String? etd;

  ShippingCostModel({
    this.name,
    this.code,
    this.service,
    this.description,
    this.cost,
    this.etd,
  });

  factory ShippingCostModel.fromJson(String str) =>
      ShippingCostModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ShippingCostModel.fromMap(Map<String, dynamic> json) =>
      ShippingCostModel(
        name: json["name"],
        code: json["code"],
        service: json["service"],
        description: json["description"],
        cost: json["cost"],
        etd: json["etd"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "code": code,
        "service": service,
        "description": description,
        "cost": cost,
        "etd": etd,
      };
}
```

Penjelasan: satu objek mewakili satu layanan pengiriman (contoh: JNE REG) lengkap dengan biaya `cost` dan estimasi hari `etd`.

### Langkah 3 - Buat `checkout_model.dart`

`lib/resource/model/checkout_model.dart`

```dart
import 'dart:convert';

class CheckoutModel {
  String provinceName;
  String cityName;
  String districtName;
  String subdistrictName;
  String zipCode;
  String fullAddress;
  int weight;
  String shippingCourier;
  String shippingService;
  int shippingCost;
  int total;

  CheckoutModel({
    required this.provinceName,
    required this.cityName,
    required this.districtName,
    required this.subdistrictName,
    required this.zipCode,
    required this.fullAddress,
    required this.weight,
    required this.shippingCourier,
    required this.shippingService,
    required this.shippingCost,
    required this.total,
  });

  @override
  String toString() {
    return 'CheckoutModel(provinceName: $provinceName, cityName: $cityName, districtName: $districtName, subdistrictName: $subdistrictName, zipCode: $zipCode, fullAddress: $fullAddress, weight: $weight, shippingCourier: $shippingCourier, shippingService: $shippingService, shippingCost: $shippingCost, total: $total)';
  }

  CheckoutModel copyWith({
    String? provinceName,
    String? cityName,
    String? districtName,
    String? subdistrictName,
    String? zipCode,
    String? fullAddress,
    int? weight,
    String? shippingCourier,
    String? shippingService,
    int? shippingCost,
    int? total,
  }) {
    return CheckoutModel(
      provinceName: provinceName ?? this.provinceName,
      cityName: cityName ?? this.cityName,
      districtName: districtName ?? this.districtName,
      subdistrictName: subdistrictName ?? this.subdistrictName,
      zipCode: zipCode ?? this.zipCode,
      fullAddress: fullAddress ?? this.fullAddress,
      weight: weight ?? this.weight,
      shippingCourier: shippingCourier ?? this.shippingCourier,
      shippingService: shippingService ?? this.shippingService,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provinceName': provinceName,
      'cityName': cityName,
      'districtName': districtName,
      'subdistrictName': subdistrictName,
      'zipCode': zipCode,
      'fullAddress': fullAddress,
      'weight': weight,
      'shippingCourier': shippingCourier,
      'shippingService': shippingService,
      'shippingCost': shippingCost,
      'total': total,
    };
  }

  factory CheckoutModel.fromMap(Map<String, dynamic> map) {
    return CheckoutModel(
      provinceName: map['provinceName'] as String,
      cityName: map['cityName'] as String,
      districtName: map['districtName'] as String,
      subdistrictName: map['subdistrictName'] as String,
      zipCode: map['zipCode'] as String,
      fullAddress: map['fullAddress'] as String,
      weight: map['weight'] as int,
      shippingCourier: map['shippingCourier'] as String,
      shippingService: map['shippingService'] as String,
      shippingCost: map['shippingCost'] as int,
      total: map['total'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory CheckoutModel.fromJson(String source) =>
      CheckoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant CheckoutModel other) {
    if (identical(this, other)) return true;

    return other.provinceName == provinceName &&
        other.cityName == cityName &&
        other.districtName == districtName &&
        other.subdistrictName == subdistrictName &&
        other.zipCode == zipCode &&
        other.fullAddress == fullAddress &&
        other.weight == weight &&
        other.shippingCourier == shippingCourier &&
        other.shippingService == shippingService &&
        other.shippingCost == shippingCost &&
        other.total == total;
  }

  @override
  int get hashCode {
    return provinceName.hashCode ^
        cityName.hashCode ^
        districtName.hashCode ^
        subdistrictName.hashCode ^
        zipCode.hashCode ^
        fullAddress.hashCode ^
        weight.hashCode ^
        shippingCourier.hashCode ^
        shippingService.hashCode ^
        shippingCost.hashCode ^
        total.hashCode;
  }
}
```

Penjelasan: model ini membawa semua data yang dikirim ke endpoint checkout. Berbeda dengan dua model sebelumnya, semua properti `required` karena form checkout wajib terisi penuh sebelum tombol bayar aktif.

### Langkah 4 - Buat `checkout_remote_resource.dart`

Buat file di folder `lib/resource/remote/`.

`lib/resource/remote/checkout_remote_resource.dart`

```dart
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_foodstore/resource/model/checkout_model.dart';
import 'package:flutter_foodstore/resource/model/location_model.dart';
import 'package:flutter_foodstore/resource/model/shipping_cost_model.dart';

class CheckoutRemoteResource {
  final Dio _dio;
  CheckoutRemoteResource(this._dio);

  Future<Either<String, List<LocationModel>>> getLocation(String search) async {
    try {
      final response =
          await _dio.get('public/search-destination?search=$search');
      List<dynamic> data = response.data;
      final result = data.map((e) => LocationModel.fromMap(e)).toList();
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<ShippingCostModel>>> getShippingCost(
    int cityId,
    int weight,
    String courierName,
  ) async {
    try {
      final response = await _dio.post(
        'public/check-ongkir',
        data: {
          'destination': cityId,
          'weight': weight,
          'courier': courierName,
        },
      );
      List<dynamic> data = response.data;
      final result = data.map((e) => ShippingCostModel.fromMap(e)).toList();
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, String>> checkOut(CheckoutModel checkout) async {
    try {
      final response = await _dio.post('public/checkout', data: {
        'province_name': checkout.provinceName,
        'city_name': checkout.cityName,
        'district_name': checkout.districtName,
        'subdistrict_name': checkout.subdistrictName,
        'zip_code': checkout.zipCode,
        'full_address': checkout.fullAddress,
        'weight': checkout.weight,
        'shipping_courier': checkout.shippingCourier,
        'shipping_service': checkout.shippingService,
        'shipping_cost': checkout.shippingCost,
        'total': checkout.total,
      });
      return Right(response.data['data']['snap_token']);
    } on DioException catch (e) {
      return Left(e.toString());
    }
  }
}
```

**Penjelasan wajib per bagian:**

- Import: `dio` (HTTP client), `either_dart` (membungkus hasil menjadi `Right` sukses atau `Left` gagal), dan tiga model.
- Class `CheckoutRemoteResource`: menerima `Dio` lewat constructor (dependency injection) sehingga mudah diuji.
- `getLocation(String search)`: GET ke `public/search-destination` dengan parameter pencarian. Jika sukses respons diubah menjadi `List<LocationModel>`, jika gagal mengembalikan pesan error.
- `getShippingCost(int cityId, int weight, String courierName)`: POST ke `public/check-ongkir` dengan ID kota tujuan, berat barang, dan nama kurir.
- `checkOut(CheckoutModel checkout)`: POST ke `public/checkout`. Jika sukses mengembalikan `snap_token` dari Midtrans yang dipakai untuk membuka halaman pembayaran.

---

## 5.2 Membuat BLoC Cubit

**Pembuka:** di materi ini dibuat tiga cubit: `CheckoutCubit` (proses checkout), `ShippingCostCubit` (menghitung biaya pengiriman), dan `LocationCubit` (mencari lokasi tujuan).

> Cara membuat: klik kanan folder `lib/bloc`, pilih **BLoC: New Cubit**, beri nama sesuai cubit. Setelah ter-generate, ubah nama foldernya (`cubit` menjadi `checkout`, `shipping_cost`, `location`). Setelah mengetik kode tiap cubit, jalankan:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Langkah 1 - Cubit Checkout

`lib/bloc/checkout/checkout_state.dart`

```dart
part of 'checkout_cubit.dart';

@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState.initial() = _Initial;
  const factory CheckoutState.loading() = _Loading;
  const factory CheckoutState.success(String message) = _Success;
  const factory CheckoutState.error(String message) = _Error;
}
```

`lib/bloc/checkout/checkout_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/checkout_model.dart';
import 'package:flutter_foodstore/resource/remote/checkout_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_state.dart';
part 'checkout_cubit.freezed.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutRemoteResource checkoutRemoteResource;
  CheckoutCubit(this.checkoutRemoteResource) : super(CheckoutState.initial());

  void checkout(CheckoutModel checkout) async {
    final result = await checkoutRemoteResource.checkOut(checkout);
    result.fold(
      (error) => emit(CheckoutState.error(error)),
      (message) => emit(CheckoutState.success(message)),
    );
  }
}
```

### Langkah 2 - Cubit ShippingCost

`lib/bloc/shipping_cost/shipping_cost_state.dart`

```dart
part of 'shipping_cost_cubit.dart';

@freezed
class ShippingCostState with _$ShippingCostState {
  const factory ShippingCostState.initial() = _Initial;
  const factory ShippingCostState.loading() = _Loading;
  const factory ShippingCostState.loaded(List<ShippingCostModel> shippingCost) =
      _Loaded;
  const factory ShippingCostState.error(dynamic message) = _Error;
}
```

`lib/bloc/shipping_cost/shipping_cost_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/shipping_cost_model.dart';
import 'package:flutter_foodstore/resource/remote/checkout_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shipping_cost_state.dart';
part 'shipping_cost_cubit.freezed.dart';

class ShippingCostCubit extends Cubit<ShippingCostState> {
  final CheckoutRemoteResource checkoutRemoteResource;
  ShippingCostCubit(this.checkoutRemoteResource)
      : super(ShippingCostState.initial());

  getShippingCost(int destination, int weight, String courier) async {
    emit(ShippingCostState.loading());
    final result = await checkoutRemoteResource.getShippingCost(
      destination,
      weight,
      courier,
    );
    result.fold(
      (error) => emit(ShippingCostState.error(error)),
      (shippingCost) => emit(ShippingCostState.loaded(shippingCost)),
    );
  }

  resetShippingCost() {
    emit(ShippingCostState.initial());
  }
}
```

### Langkah 3 - Cubit Location

`lib/bloc/location/location_state.dart`

```dart
part of 'location_cubit.dart';

@freezed
class LocationState with _$LocationState {
  const factory LocationState.initial() = _Initial;
  const factory LocationState.loading() = _Loading;
  const factory LocationState.loaded(List<LocationModel> locations) = _Loaded;
  const factory LocationState.error(String message) = _Error;
}
```

`lib/bloc/location/location_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/resource/model/location_model.dart';
import 'package:flutter_foodstore/resource/remote/checkout_remote_resource.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_state.dart';
part 'location_cubit.freezed.dart';

class LocationCubit extends Cubit<LocationState> {
  final CheckoutRemoteResource checkoutRemoteResource;
  LocationCubit(this.checkoutRemoteResource) : super(LocationState.initial());

  getLocation(String search) async {
    emit(LocationState.loading());
    final result = await checkoutRemoteResource.getLocation(search);
    result.fold(
      (message) => emit(LocationState.error(message)),
      (location) => emit(LocationState.loaded(location)),
    );
  }

  void clearLocation() {
    emit(LocationState.initial());
  }
}
```

**Penjelasan wajib:**

- `CheckoutCubit.checkout()` memanggil `checkOut` pada remote resource. Hasil `Left` menjadi state `error`, hasil `Right` (berisi `snap_token`) menjadi state `success`.
- `ShippingCostCubit.getShippingCost()` mengeluarkan state `loading`, lalu `loaded` berisi list layanan atau `error`. `resetShippingCost()` mengembalikan ke `initial`.
- `LocationCubit.getLocation()` mencari lokasi. `clearLocation()` mengosongkan hasil pencarian setelah pengguna memilih satu lokasi.
- Semua state memakai `freezed` sehingga di UI bisa dipakai `state.maybeWhen(...)`.

---

## 5.3 Implementasi CheckoutRemoteResource

**Pembuka:** setelah `CheckoutRemoteResource` dibuat, sekarang diinisialisasi di `main.dart` lalu di-inject ke `AppRouter`.

### Langkah 1 - Edit `main.dart`

Inisialisasi di `main()`:

```dart
final checkoutRemoteResource = CheckoutRemoteResource(dio);
```

Lalu masukkan ke `AppRouter`:

```dart
final appRouter = AppRouter(
  authBloc: authBloc,
  orderRemoteResource: orderRemoteResource,
  homeRemoteResource: homeRemoteResource,
  checkoutRemoteResource: checkoutRemoteResource,
);
```

Sehingga keseluruhan kode `main.dart` menjadi:

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foodstore/bloc/auth/auth_bloc.dart';
import 'package:flutter_foodstore/bloc/cart/cart_bloc.dart';
import 'package:flutter_foodstore/bloc/category/category_cubit.dart';
import 'package:flutter_foodstore/bloc/order/order_cubit.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/bloc/product_populer/product_populer_cubit.dart';
import 'package:flutter_foodstore/bloc/profile/profile_bloc.dart';
import 'package:flutter_foodstore/bloc/slider/slider_cubit.dart';
import 'package:flutter_foodstore/core/constants/app_config.dart';
import 'package:flutter_foodstore/core/utils/auth_interceptor.dart';
import 'package:flutter_foodstore/resource/remote/auth_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/cart_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/checkout_remote_resource.dart';
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
  final cartRemoteResource = CartRemoteResource(dio);
  final checkoutRemoteResource = CheckoutRemoteResource(dio);
  final authBloc = AuthBloc(authRemoteResource)
    ..add(AuthEvent.checkLoginStatus());
  final appRouter = AppRouter(
    authBloc: authBloc,
    orderRemoteResource: orderRemoteResource,
    homeRemoteResource: homeRemoteResource,
    checkoutRemoteResource: checkoutRemoteResource,
  );
  dio.interceptors.add(AuthInterceptor(authBloc));
  runApp(MyApp(
    appRouter: appRouter,
    authBloc: authBloc,
    profileRemoteResource: profileRemoteResource,
    orderRemoteResource: orderRemoteResource,
    homeRemoteResource: homeRemoteResource,
    cartRemoteResource: cartRemoteResource,
  ));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  final AuthBloc authBloc;
  final ProfileRemoteResource profileRemoteResource;
  final OrderRemoteResource orderRemoteResource;
  final HomeRemoteResource homeRemoteResource;
  final CartRemoteResource cartRemoteResource;
  const MyApp({
    super.key,
    required this.appRouter,
    required this.authBloc,
    required this.profileRemoteResource,
    required this.orderRemoteResource,
    required this.homeRemoteResource,
    required this.cartRemoteResource,
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
          create: (_) => CategoryCubit(homeRemoteResource)..fetchCategory(),
        ),
        BlocProvider(
          create: (_) => ProductCubit(homeRemoteResource)..fetchProduct(),
        ),
        BlocProvider(
          create: (_) =>
              ProductPopulerCubit(homeRemoteResource)..fetchProductPopuler(),
        ),
        BlocProvider(
          create: (context) => CartBloc(cartRemoteResource),
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

> Catatan untuk AI: nama method `fecthSlider` (ada typo) adalah nama method asli dari Bab 7 pada `SliderCubit`. Jangan dikoreksi karena akan membuat kode tidak cocok dengan bab sebelumnya.

**Penjelasan wajib:**

- `checkoutRemoteResource` dibuat dari instance `dio` yang sama dengan resource lain, sehingga interceptor token ikut berlaku.
- `AppRouter` sekarang menerima `checkoutRemoteResource` karena route `/checkout` akan membuat tiga cubit yang membutuhkannya.
- `MyApp` tidak menyediakan `CheckoutCubit`, `ShippingCostCubit`, dan `LocationCubit` secara global. Ketiganya hanya dibuat saat halaman checkout dibuka (lihat materi 5.4).

### Langkah 2 - Edit `app_router.dart` (tambah dependency)

Tambahkan properti dan parameter constructor pada `AppRouter`:

```dart
class AppRouter {
  final AuthBloc authBloc;
  final OrderRemoteResource orderRemoteResource;
  final HomeRemoteResource homeRemoteResource;
  final CheckoutRemoteResource checkoutRemoteResource;

  AppRouter({
    required this.authBloc,
    required this.orderRemoteResource,
    required this.homeRemoteResource,
    required this.checkoutRemoteResource,
  });
  // ... (router di bawahnya tidak berubah di langkah ini)
}
```

> Catatan untuk AI: kode lengkap `app_router.dart` ditampilkan di materi 5.4 (setelah route checkout ditambahkan). Di materi ini cukup tunjukkan potongan di atas agar pembaca paham penambahan parameter.

---

## 5.4 Implementasi BLoC dan Navigasi

**Pembuka:** setelah `CheckoutRemoteResource` diinisialisasi, sekarang dibuat halaman dasar checkout, route-nya, lalu BLoC dipasang lewat `MultiBlocProvider`.

### Langkah 1 - Membuat Navigasi

Buat folder `checkout` di dalam `lib/page/`, lalu buat file `checkout_page.dart` berisi layout dasar.

`lib/page/checkout/checkout_page.dart`

```dart
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final int totalPrice;
  final int totalWeight;
  const CheckoutPage({
    super.key,
    required this.totalPrice,
    required this.totalWeight,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
```

Penjelasan: `CheckoutPage` menerima dua parameter, `totalPrice` (total harga item) dan `totalWeight` (total berat), yang nanti dipakai untuk menghitung ongkos kirim.

Lalu tambahkan route di `app_router.dart`, di dalam daftar `routes` setelah route `/productByCategory`:

```dart
GoRoute(
  path: '/checkout',
  builder: (context, state) {
    String totalPrice = state.uri.queryParameters['totalPrice'] ?? '0';
    String totalWeight = state.uri.queryParameters['totalWeight'] ?? '0';
    return CheckoutPage(
      totalPrice: int.parse(totalPrice),
      totalWeight: int.parse(totalWeight),
    );
  },
),
```

Penjelasan: `path: '/checkout'` adalah nama route. `totalPrice` dan `totalWeight` diambil dari query parameter, contoh pemanggilan `/checkout?totalPrice=5000&totalWeight=2`.

### Langkah 2 - Implementasi BLoC

Halaman checkout butuh lebih dari satu BLoC, jadi route `/checkout` dibungkus `MultiBlocProvider`:

```dart
GoRoute(
  path: '/checkout',
  builder: (context, state) {
    final String totalPrice = state.uri.queryParameters['totalPrice'] ?? '0';
    final String totalWeight = state.uri.queryParameters['totalWeight'] ?? '0';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ShippingCostCubit(checkoutRemoteResource),
        ),
        BlocProvider(
          create: (context) => CheckoutCubit(checkoutRemoteResource),
        ),
        BlocProvider(
          create: (context) => LocationCubit(checkoutRemoteResource),
        ),
      ],
      child: CheckoutPage(
        totalPrice: int.parse(totalPrice),
        totalWeight: int.parse(totalWeight),
      ),
    );
  },
),
```

Kode lengkap `app_router.dart` setelah materi ini:

`lib/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/auth/auth_bloc.dart';
import 'package:flutter_foodstore/bloc/cart/cart_bloc.dart';
import 'package:flutter_foodstore/bloc/category/category_cubit.dart';
import 'package:flutter_foodstore/bloc/checkout/checkout_cubit.dart';
import 'package:flutter_foodstore/bloc/location/location_cubit.dart';
import 'package:flutter_foodstore/bloc/order/order_cubit.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/bloc/profile/profile_bloc.dart';
import 'package:flutter_foodstore/bloc/review_product/review_product_cubit.dart';
import 'package:flutter_foodstore/bloc/shipping_cost/shipping_cost_cubit.dart';
import 'package:flutter_foodstore/page/auth/login_page.dart';
import 'package:flutter_foodstore/page/auth/register_page.dart';
import 'package:flutter_foodstore/page/checkout/checkout_page.dart';
import 'package:flutter_foodstore/page/dashboard/cart_page.dart';
import 'package:flutter_foodstore/page/dashboard/dashboard_page.dart';
import 'package:flutter_foodstore/page/dashboard/home_page.dart';
import 'package:flutter_foodstore/page/dashboard/order_page.dart';
import 'package:flutter_foodstore/page/dashboard/profile_page.dart';
import 'package:flutter_foodstore/page/midtrans/midtrans_payment_page.dart';
import 'package:flutter_foodstore/page/order/order_detail_page.dart';
import 'package:flutter_foodstore/page/product/all_product_page.dart';
import 'package:flutter_foodstore/page/product/detail_product_page.dart';
import 'package:flutter_foodstore/page/product/product_by_category_page.dart';
import 'package:flutter_foodstore/resource/model/category_model.dart';
import 'package:flutter_foodstore/resource/remote/checkout_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/home_remote_resource.dart';
import 'package:flutter_foodstore/resource/remote/order_remote_resource.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthBloc authBloc;
  final OrderRemoteResource orderRemoteResource;
  final HomeRemoteResource homeRemoteResource;
  final CheckoutRemoteResource checkoutRemoteResource;

  AppRouter({
    required this.authBloc,
    required this.orderRemoteResource,
    required this.homeRemoteResource,
    required this.checkoutRemoteResource,
  });

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: '/dashboard/home',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is Authenticated;
      final protectedRoutes = [
        '/dashboard/order',
        '/dashboard/profile',
        '/dashboard/cart',
        '/order',
        '/checkout',
      ];

      final isProtected = protectedRoutes
          .any((route) => state.matchedLocation.startsWith(route));

      if (!isLoggedIn && isProtected) return '/login';

      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/login';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (_, __, child) => DashboardPage(child: child),
        routes: [
          GoRoute(
            path: '/dashboard/home',
            builder: (_, __) {
              return HomePage();
            },
          ),
          GoRoute(
            path: '/dashboard/order',
            builder: (context, state) {
              context.read<OrderCubit>().fetchOrders(isRefresh: true);
              return OrderPage();
            },
          ),
          GoRoute(
            path: '/dashboard/cart',
            builder: (context, state) {
              context.read<CartBloc>().add(CartEvent.fetchCart());
              return CartPage();
            },
          ),
          GoRoute(
            path: '/dashboard/profile',
            builder: (context, state) {
              context.read<ProfileBloc>().add(ProfileEvent.loadProfile());
              return ProfilePage();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => RegisterPage(),
      ),
      GoRoute(
        path: '/orderDetail/:snapToken',
        builder: (context, state) {
          final snapToken = state.pathParameters['snapToken'] ?? '';
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    OrderCubit(orderRemoteResource)..detailOrder(snapToken),
              ),
              BlocProvider(
                create: (context) => ReviewProductCubit(
                  orderRemoteResource,
                ),
              ),
            ],
            child: OrderDetailPage(),
          );
        },
      ),
      GoRoute(
        path: '/midtransPayment/:snapToken',
        builder: (context, state) {
          return MidtransPaymentPage(
            snapToken: state.pathParameters['snapToken'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/allProducts',
        builder: (context, state) => BlocProvider(
          create: (context) =>
              ProductCubit(homeRemoteResource)..fetchProduct(isRefresh: true),
          child: AllProductPage(),
        ),
      ),
      GoRoute(
        path: '/detailProduct/:slug',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => ProductCubit(homeRemoteResource)
              ..detailProduct(state.pathParameters['slug'] ?? ''),
            child: DetailProductPage(),
          );
        },
      ),
      GoRoute(
        path: '/productByCategory',
        builder: (context, state) {
          final category = state.extra as CategoryModel;
          return BlocProvider(
            create: (context) => CategoryCubit(homeRemoteResource)
              ..fetchCategoryBySlug(category.slug ?? ''),
            child: ProductByCategoryPage(categoryName: category.name ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final String totalPrice =
              state.uri.queryParameters['totalPrice'] ?? '0';
          final String totalWeight =
              state.uri.queryParameters['totalWeight'] ?? '0';
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ShippingCostCubit(checkoutRemoteResource),
              ),
              BlocProvider(
                create: (context) => CheckoutCubit(checkoutRemoteResource),
              ),
              BlocProvider(
                create: (context) => LocationCubit(checkoutRemoteResource),
              ),
            ],
            child: CheckoutPage(
              totalPrice: int.parse(totalPrice),
              totalWeight: int.parse(totalWeight),
            ),
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}
```

> Catatan untuk AI: pada `redirect`, kondisi `isLoggedIn && state.matchedLocation == '/login'` mengembalikan `'/login'`. Itu sesuai kode sumber, jangan diubah.

**Penjelasan wajib:**

- `CheckoutPage` dibungkus `MultiBlocProvider` sehingga tiga cubit (`ShippingCostCubit`, `CheckoutCubit`, `LocationCubit`) tersedia untuk seluruh widget di halaman checkout.
- `/checkout` sudah masuk `protectedRoutes`, jadi pengguna yang belum login diarahkan ke `/login`.

### Langkah 3 - Uji Coba

Buka halaman cart, klik tombol **Proceed to Checkout**. Aplikasi akan membuka `CheckoutPage`, tetapi masih berupa layar putih karena tampilannya belum dibuat.

---

## 5.5 Membuat Tampilan Search Location

**Pembuka:** halaman checkout masih blank. Di materi ini dibuat tampilan untuk mencari lokasi tujuan dan mengisi alamat.

### Langkah 1 - Edit `checkout_page.dart`

> Catatan untuk AI: kode lengkap `checkout_page.dart` versi akhir ada di materi 5.7. Untuk materi ini tulis kode lengkap versi bertahap berikut, dibentuk dari versi akhir dengan aturan:
> - Hapus import `checkout_cubit.dart`, `shipping_cost_cubit.dart`, `currency_helper.dart`, `checkout_model.dart`, `shipping_cost_model.dart`.
> - Hapus `shippingMethods`, `selectedShipping`, `selectShippingCost`, `shippingCostModel`, `isFormValid`, `initState` listener, `dispose`, `_validateForm`, `_buildShippingMethodDropdown`, `_buildShippingCost`, `_buildPriceRow`, `_buildButtonPay`, dan seluruh pemanggilan `_validateForm()`.
> - `initState` hanya berisi `totalItems = widget.totalPrice;` lalu `super.initState();`.
> - `body` hanya memuat satu `_buildSection` bertajuk "Shipping Information" (isi `_buildLocation()` dan `_buildAddressField()`), tanpa `bottomNavigationBar`.
> - `_messageEror` dihapus pada versi ini.

Bagian-bagian penting pada versi ini:

```dart
final TextEditingController addressController = TextEditingController();
final TextEditingController locationController = TextEditingController();
final _formKey = GlobalKey<FormState>();
LocationModel? selectLocation;
int totalItems = 0;

@override
void initState() {
  totalItems = widget.totalPrice;
  super.initState();
}
```

```dart
PreferredSizeWidget _appBar() {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.primary,
    leading: IconButton(
      onPressed: () {
        context.pop();
      },
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
    ),
    title: const Text(
      'Checkout',
      style: TextStyle(color: Colors.white),
    ),
  );
}
```

Penjelasan wajib:

- Import `flutter_bloc`, `location_cubit.dart`, `location_model.dart`, dan `go_router`.
- Dua `TextEditingController` (lokasi dan alamat), `_formKey` untuk validasi form, dan `LocationModel? selectLocation` untuk menyimpan lokasi yang dipilih pengguna.
- `totalItems` diisi dari `widget.totalPrice` di `initState()`.
- `_appBar()`: ikon back kustom, warna sesuai warna primer, `context.pop()` kembali ke halaman sebelumnya.
- Seluruh form dibungkus `Form` dan `SingleChildScrollView`.
- `_buildSection` adalah widget reusable (judul, ikon, dan child) dengan container putih membulat dan bayangan. Kode lengkapnya ada di 5.7.
- `_buildLocation`: `TextFormField` "Search Location" dengan tombol `IconButton.filled` bergambar search. Jika kosong tampil `SnackBar` merah "Please Select Location", jika terisi memanggil `context.read<LocationCubit>().getLocation(locationController.text)`. Di bawahnya `BlocBuilder<LocationCubit, LocationState>` menampilkan loading atau daftar lokasi.
- `_buildLocationList`: `SizedBox` tinggi 200 berisi `ListView.builder`. Saat item di-tap, teks lokasi diisi ke `locationController`, `selectLocation` diisi, lalu `clearLocation()` dipanggil agar daftar tertutup.
- `_buildAddressField`: `TextFormField` "Address" dengan `maxLines: 3` dan validator "Please enter your address".

---

## 5.6 Menghitung Biaya Ongkos Kirim

**Pembuka:** setelah pencarian lokasi jalan, sekarang menghitung biaya ongkos kirim memakai RajaOngkir.

### Langkah 1 - Edit `checkout_page.dart`

> Catatan untuk AI: tulis kode lengkap versi bertahap, dibentuk dari versi akhir (5.7) dengan aturan: hapus import `checkout_cubit.dart` dan `checkout_model.dart`; hapus `isFormValid`, listener di `initState`, `dispose`, `_validateForm`, `_buildButtonPay`, dan semua pemanggilan `_validateForm()`; `bottomNavigationBar` hanya berisi tiga baris harga (Total Items, Shipping Cost, Grand Total) tanpa `_buildButtonPay(context)`. `_messageEror` ikut ada. `initState` hanya `totalItems = widget.totalPrice; super.initState();`.

Penambahan inti pada versi ini:

```dart
import 'package:flutter_foodstore/bloc/shipping_cost/shipping_cost_cubit.dart';
import 'package:flutter_foodstore/core/utils/currency_helper.dart';
import 'package:flutter_foodstore/resource/model/shipping_cost_model.dart';
```

```dart
final List<String> shippingMethods = [
  'POS',
  'JNE',
  'TIKI',
  'SiCepat',
  'JNT',
  'Ninja',
  'Lion',
  'Anteraja',
  'NCS',
  'Rex',
  'Sentral',
  'Star',
  'Wahana',
];
String? selectedShipping;
int? selectShippingCost = 0;
ShippingCostModel? shippingCostModel;
```

Section baru di `body` setelah "Shipping Information":

```dart
_buildSection(
  title: 'Select Shipping Method',
  icon: Icons.local_shipping_outlined,
  child: Column(
    spacing: 16.0,
    children: [
      _buildShippingMethodDropdown(),
      _buildShippingCost(),
    ],
  ),
),
```

`_buildShippingMethodDropdown()`, `_buildShippingCost()`, dan `bottomNavigationBar` memakai kode yang sama dengan versi akhir di 5.7 (tanpa pemanggilan `_validateForm()`).

**Penjelasan wajib:**

- `shippingMethods` adalah daftar kurir. `selectedShipping` menyimpan kurir terpilih, `selectShippingCost` menyimpan biaya, `shippingCostModel` menyimpan layanan terpilih.
- `_buildShippingMethodDropdown`: `DropdownButtonFormField<String>`. Saat kurir dipilih, `selectShippingCost` direset ke `null`. Jika lokasi belum dipilih tampil snackbar "Please Select Location". Jika sudah, memanggil `ShippingCostCubit.getShippingCost(selectLocation?.id ?? 0, widget.totalWeight, value?.toLowerCase() ?? '')`.
- `_buildShippingCost`: `BlocBuilder<ShippingCostCubit, ShippingCostState>` menampilkan loading, daftar `RadioListTile<ShippingCostModel>` (judul `deskripsi - harga rupiah`, subjudul `Estimasi: ... hari`), atau pesan "Tidak ada data tersedia" jika kosong.
- `bottomNavigationBar`: container putih berisi tiga baris harga lewat `_buildPriceRow` (Total Items, Shipping Cost, Grand Total dengan `totalItems + (selectShippingCost ?? 0)`).

### Langkah 2 - Uji Coba

Jalankan ulang project. Pilih lokasi, pilih kurir (contoh POS), maka tampil beberapa pilihan layanan beserta harga dan estimasi hari. Setelah satu layanan dipilih, bagian bawah menampilkan rincian harga.

---

## 5.7 Membuat Proses Checkout

**Pembuka:** setelah ongkir bisa dihitung, sekarang dibuat proses checkout. Alurnya: setelah lokasi, alamat, ekspedisi, dan biaya terisi, tombol pembayaran aktif dan mengarahkan pengguna ke Midtrans.

### Langkah 1 - Edit `checkout_page.dart` (versi akhir)

`lib/page/checkout/checkout_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/checkout/checkout_cubit.dart';
import 'package:flutter_foodstore/bloc/location/location_cubit.dart';
import 'package:flutter_foodstore/bloc/shipping_cost/shipping_cost_cubit.dart';
import 'package:flutter_foodstore/core/utils/currency_helper.dart';
import 'package:flutter_foodstore/resource/model/checkout_model.dart';
import 'package:flutter_foodstore/resource/model/location_model.dart';
import 'package:flutter_foodstore/resource/model/shipping_cost_model.dart';
import 'package:go_router/go_router.dart';

class CheckoutPage extends StatefulWidget {
  final int totalPrice;
  final int totalWeight;
  const CheckoutPage({
    super.key,
    required this.totalPrice,
    required this.totalWeight,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LocationModel? selectLocation;
  int totalItems = 0;

  final List<String> shippingMethods = [
    'POS',
    'JNE',
    'TIKI',
    'SiCepat',
    'JNT',
    'Ninja',
    'Lion',
    'Anteraja',
    'NCS',
    'Rex',
    'Sentral',
    'Star',
    'Wahana',
  ];
  String? selectedShipping;
  int? selectShippingCost = 0;
  ShippingCostModel? shippingCostModel;

  bool isFormValid = false;

  @override
  void initState() {
    totalItems = widget.totalPrice;
    addressController.addListener(_validateForm);
    locationController.addListener(_validateForm);
    super.initState();
  }

  @override
  void dispose() {
    addressController.removeListener(_validateForm);
    locationController.removeListener(_validateForm);
    addressController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final valid = addressController.text.isNotEmpty &&
        locationController.text.isNotEmpty &&
        selectedShipping != null &&
        selectedShipping!.isNotEmpty &&
        selectShippingCost != null &&
        selectShippingCost! > 0 &&
        selectLocation != null;
    if (isFormValid != valid) {
      setState(() => isFormValid = valid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Scaffold(
        appBar: _appBar(),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 16.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Shipping Information',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      spacing: 16.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocation(),
                        _buildAddressField(),
                      ],
                    ),
                  ),
                  _buildSection(
                    title: 'Select Shipping Method',
                    icon: Icons.local_shipping_outlined,
                    child: Column(
                      spacing: 16.0,
                      children: [
                        _buildShippingMethodDropdown(),
                        _buildShippingCost(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          color: Colors.white,
          child: Column(
            spacing: 8.0,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPriceRow(
                title: 'Total Items:',
                fontSize: 16.0,
                price: widget.totalPrice,
              ),
              _buildPriceRow(
                title: 'Shipping Cost:',
                fontSize: 16.0,
                price: selectShippingCost ?? 0,
              ),
              Divider(
                thickness: 2,
                color: Colors.grey[300],
              ),
              _buildPriceRow(
                title: 'Grand Total:',
                fontSize: 18.0,
                price: totalItems + (selectShippingCost ?? 0),
                isBold: true,
              ),
              _buildButtonPay(context),
            ],
          ),
        ),
      );
    });
  }

  // appBar
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: IconButton(
        onPressed: () {
          context.pop();
        },
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
      title: const Text(
        'Checkout',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 12),
          child
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      spacing: 12.0,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Search Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Search Location cannot be empty'
                    : null,
              ),
            ),
            IconButton.filled(
              onPressed: () {
                if (locationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please Select Location'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                context
                    .read<LocationCubit>()
                    .getLocation(locationController.text);
              },
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
          ],
        ),
        BlocBuilder<LocationCubit, LocationState>(builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (locations) => _buildLocationList(locations),
            orElse: () => const SizedBox(),
          );
        }),
      ],
    );
  }

  Widget _buildLocationList(List<LocationModel> locations) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return ListTile(
            title: Text(location.label.toString()),
            onTap: () {
              setState(() {
                locationController.text = location.label.toString();
                selectLocation = location;
              });
              context.read<LocationCubit>().clearLocation();
              _validateForm();
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: addressController,
      decoration: const InputDecoration(
        labelText: 'Address',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please enter your address' : null,
      maxLines: 3,
    );
  }

  Widget _buildShippingMethodDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
      ),
      value: selectedShipping,
      items: shippingMethods
          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
          .toList(),
      hint: const Text('Select Shipping Method'),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Please Select Shipping Method'
          : null,
      onChanged: (value) {
        selectShippingCost = null;
        if (selectLocation == null) {
          _messageEror('Please Select Location');
          return;
        }
        context.read<ShippingCostCubit>().getShippingCost(
              selectLocation?.id ?? 0,
              widget.totalWeight,
              value?.toLowerCase() ?? '',
            );
        setState(() => selectedShipping = value);
        _validateForm();
      },
    );
  }

  Widget _buildShippingCost() {
    return BlocBuilder<ShippingCostCubit, ShippingCostState>(
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (shippingCost) {
            if (shippingCost.isEmpty) {
              return const Center(child: Text("Tidak ada data tersedia"));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shippingCost.length,
              itemBuilder: (context, index) {
                final option = shippingCost[index];
                return RadioListTile<ShippingCostModel>(
                  title: Text(
                      "${option.description} - ${CurrencyHelper.formatRupiah(option.cost?.toDouble() ?? 0)}"),
                  subtitle: Text("Estimasi: ${option.etd} hari"),
                  value: option,
                  groupValue: shippingCostModel,
                  onChanged: (value) {
                    setState(() {
                      selectShippingCost = value?.cost ?? 0;
                      shippingCostModel = option;
                    });
                    _validateForm();
                  },
                );
              },
            );
          },
          error: (message) => Center(child: Text(message)),
          orElse: () => const SizedBox(),
        );
      },
    );
  }

  Widget _buildPriceRow({
    required String title,
    required int price,
    required double fontSize,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold == true ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyHelper.formatRupiah(price.toDouble()),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold == true ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonPay(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        state.maybeWhen(
          success: (snapToken) async {
            final result = await context.push('/midtransPayment/$snapToken');
            if (result == 'success') {
              _navigateToDetailOrder(snapToken);
            } else {
              _navigateToDetailOrder(snapToken);
            }
          },
          error: (message) {
            _messageEror(message);
          },
          orElse: () {},
        );
      },
      child: FilledButton(
        onPressed: isFormValid
            ? () {
                if (_formKey.currentState!.validate()) {
                  final checkout = CheckoutModel(
                    provinceName: selectLocation?.provinceName ?? "",
                    cityName: selectLocation?.cityName ?? "",
                    districtName: selectLocation?.districtName ?? "",
                    subdistrictName: selectLocation?.subdistrictName ?? "",
                    zipCode: selectLocation?.zipCode ?? "",
                    fullAddress: addressController.text,
                    weight: widget.totalWeight,
                    shippingCourier: selectedShipping?.toLowerCase() ?? "",
                    shippingService:
                        shippingCostModel?.service?.toLowerCase() ?? "",
                    shippingCost: selectShippingCost ?? 0,
                    total: widget.totalPrice + (selectShippingCost ?? 0),
                  );
                  context.read<CheckoutCubit>().checkout(checkout);
                }
              }
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Center(
          child: Text('Confirm and Pay',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  void _navigateToDetailOrder(String snapToken) {
    context.go('/orderDetail/$snapToken');
  }

  void _messageEror(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}
```

**Penjelasan wajib:**

- Import baru: `checkout_cubit.dart` dan `checkout_model.dart`.
- `isFormValid` dan `_validateForm()`: tombol bayar hanya aktif jika alamat, lokasi, kurir, biaya ongkir (lebih dari 0), dan `selectLocation` semuanya terisi. Listener dipasang di `initState` dan dilepas di `dispose`. `_validateForm()` juga dipanggil saat lokasi dipilih, kurir dipilih, dan layanan ongkir dipilih.
- `_buildButtonPay`: `BlocListener<CheckoutCubit, CheckoutState>` mendengarkan hasil checkout. Saat `success` membawa `snapToken`, aplikasi membuka `/midtransPayment/$snapToken` dengan `context.push`, lalu setelah halaman pembayaran ditutup, berpindah ke detail order lewat `_navigateToDetailOrder(snapToken)`. Saat `error`, tampil snackbar merah.
- `FilledButton` "Confirm and Pay": `onPressed` bernilai `null` (tombol disable) jika `isFormValid` false. Jika true dan form valid, membuat `CheckoutModel` dari data yang dipilih (kurir dan layanan diubah ke huruf kecil, `total = totalPrice + ongkir`) lalu memanggil `context.read<CheckoutCubit>().checkout(checkout)`.

### Langkah 2 - Uji Coba Checkout

Jalankan ulang project. Selama data belum lengkap tombol pembayaran nonaktif. Setelah semua terisi, tombol aktif dan membuka halaman pembayaran Midtrans.

**Ringkasan Bab 10 (tulis di akhir bab):** pembaca sudah membuat model, remote resource, dan tiga cubit untuk checkout, menyiapkan route `/checkout` dengan `MultiBlocProvider`, membuat form lokasi, alamat, pilihan kurir, dan perhitungan ongkir, serta tombol pembayaran yang membuka Midtrans.

---

# 6. CHECKLIST HASIL AKHIR (WAJIB DICEK AI SEBELUM MENJAWAB)

File baru atau berubah setelah Bab 10 selesai:

```text
flutter_foodstore/
  lib/
    bloc/
      checkout/
        checkout_cubit.dart
        checkout_state.dart
      location/
        location_cubit.dart
        location_state.dart
      shipping_cost/
        shipping_cost_cubit.dart
        shipping_cost_state.dart
    page/
      checkout/
        checkout_page.dart
    resource/
      model/
        checkout_model.dart
        location_model.dart
        shipping_cost_model.dart
      remote/
        checkout_remote_resource.dart
    app_router.dart                 (menerima checkoutRemoteResource, route /checkout)
    main.dart                       (CheckoutRemoteResource dibuat dan dikirim ke AppRouter)
```

Pastikan:

- [ ] Semua 7 materi ada dan urutannya benar.
- [ ] Nama file, class, variabel, dan path import sama persis dengan kode acuan (termasuk `fecthSlider`, `_messageEror`, dan folder `core/components`).
- [ ] `checkout_page.dart` ditampilkan lengkap di materi 5.5, 5.6, dan 5.7 mengikuti aturan versi bertahap.
- [ ] `app_router.dart` ditampilkan lengkap di materi 5.4, `main.dart` lengkap di materi 5.3.
- [ ] Tiga cubit checkout hanya disediakan lewat `MultiBlocProvider` di route `/checkout` (tidak di `MyApp`).
- [ ] Perintah `dart run build_runner build --delete-conflicting-outputs` disebut setelah membuat state `freezed`.
- [ ] Tidak ada em dash di seluruh teks dan kode.
- [ ] Bab ditutup dengan ringkasan singkat.
- [ ] Tidak ada fitur atau package tambahan di luar daftar.

> Catatan untuk AI: pada `redirect` di `app_router.dart`, kondisi `isLoggedIn && state.matchedLocation == '/login'` mengembalikan `'/login'`. Itu sesuai kode sumber, jangan diubah.
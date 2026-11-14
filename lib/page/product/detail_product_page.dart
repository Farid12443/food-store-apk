import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/core/components/product_card.dart';

class DetailProductPage extends StatelessWidget {
  const DetailProductPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) => state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message)),
            loadedDetailProduct: (product) => SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ProductCard(product: product, isPopular: false),
            ),
            orElse: () => const Center(child: Text('Product not found')),
          ),
        ),
      );
}

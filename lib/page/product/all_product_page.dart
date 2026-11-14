import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/product/product_cubit.dart';
import 'package:flutter_foodstore/core/components/product_card.dart';

class AllProductPage extends StatelessWidget {
  const AllProductPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('All Products')),
        body: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) => state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message)),
            loadedProduct: (products, _) => ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8),
                child: ProductCard(product: products[index], isPopular: false),
              ),
            ),
            orElse: () => const Center(child: Text('No products available')),
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/category/category_cubit.dart';
import 'package:flutter_foodstore/core/components/product_card.dart';

class ProductByCategoryPage extends StatelessWidget {
  final String categoryName;
  const ProductByCategoryPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(categoryName)),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) => state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message)),
            loadedCategoryBySlug: (category) {
              final products = category.products ?? [];
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: ProductCard(product: products[index], isPopular: false),
                ),
              );
            },
            orElse: () => const Center(child: Text('No products available')),
          ),
        ),
      );
}

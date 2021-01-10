import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/app_future_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo/ui/tabs/nutrition/creation/meal_creation_screen.dart';
import 'package:nephrolog_api_client/model/product.dart';

enum ProductSearchType {
  choose,
  change,
}

Future<Product> showProductSearch(
    BuildContext context, ProductSearchType searchType) async {
  final product = await showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        searchType: searchType,
        hintText: AppLocalizations.of(context).productSearchTitle,
      ));
  return product;
}

class ProductTile extends StatelessWidget {
  final Product product;
  final GestureTapCallback onTap;

  const ProductTile({
    Key key,
    @required this.product,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      title: Text(product.name),
      leading: ProductKindIcon(
        productKind: product.productKind,
      ),
      onTap: onTap,
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Product> {
  final ProductSearchType searchType;

  ProductSearchDelegate({
    @required this.searchType,
    String hintText,
  }) : super(searchFieldLabel: hintText);

  final _apiService = ApiService();
  final _queryCancelToken = CancelToken();

  var _queryMemoizer = AsyncMemoizer<List<Product>>();
  String currentQuery;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final icon =
        searchType == ProductSearchType.choose ? Icons.arrow_back : Icons.close;

    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  void close(BuildContext context, Product result) {
    super.close(context, result);

    if (searchType == ProductSearchType.choose && result != null) {
      Navigator.of(context).pushNamed(
        Routes.ROUTE_MEAL_CREATION,
        arguments: MealCreationScreenArguments(result),
      );
    }
  }

  @override
  Widget buildResults(BuildContext context) {
    return _searchForProduct(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _searchForProduct(context, query);
  }

  void changeQuery(String query) {
    if (currentQuery != query) {
      currentQuery = query;

      _queryMemoizer = AsyncMemoizer<List<Product>>();

      _queryMemoizer.runOnce(() async {
        return await _apiService.getProducts(query, _queryCancelToken);
      });
    }
  }

  Widget _searchForProduct(BuildContext context, String query) {
    changeQuery(query);

    return Container(
      color: Colors.white,
      child: AppFutureBuilder<List<Product>>(
        future: _queryMemoizer.future,
        builder: (context, products) {
          return ListView.separated(
            key: Key("product-list-$query"),
            itemCount: products.length,
            separatorBuilder: (BuildContext context, int index) =>
                Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];

              return ProductTile(
                product: product,
                onTap: () => close(context, product),
              );
            },
          );
        },
      ),
    );
  }
}

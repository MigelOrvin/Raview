import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raview/designdata/assets/widgets/snackbar.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';
import 'package:timeago/timeago.dart' as timeago;

class AllCommentScreen extends StatefulWidget {
  final String placeId;
  final String placeName;
  final Function? onReviewDeleted;

  const AllCommentScreen({
    super.key,
    required this.placeId,
    required this.placeName,
    this.onReviewDeleted,
  });

  @override
  State<AllCommentScreen> createState() => _AllCommentScreenState();
}

class _AllCommentScreenState extends State<AllCommentScreen> {
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoading = false;
  final List<DocumentSnapshot> _reviews = [];
  final ScrollController _scrollController = ScrollController();
  
  // Filter options
  int? _selectedRatingFilter;
  bool _sortByNewest = true;
  
  DocumentSnapshot? _currentUserReview;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserReview();
    _fetchReviews();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _fetchMoreReviews();
      }
    }
  }

  Future<void> _fetchCurrentUserReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: widget.placeId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _currentUserReview = querySnapshot.docs.first;
        });
      }
    } catch (e) {
      print('Error fetching current user review: $e');
    }
  }  Future<void> _fetchReviews() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _reviews.clear(); // Clear existing reviews when fetching new ones
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: widget.placeId);
      
      // Cek rating trus dipilah
      if (_selectedRatingFilter != null) {
        query = query.where('rating', isEqualTo: _selectedRatingFilter);
      }
      
      // sm kek rating tpi timestamp
      query = query.orderBy('timestamp', descending: _sortByNewest);
      
      QuerySnapshot querySnapshot = await query.limit(_limit).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Ngeluarin data dari filterny
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final filteredDocs = querySnapshot.docs.where((doc) {
          return doc['userId'] != currentUserId;
        }).toList();
        
        if (filteredDocs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last; //pagination pagination lagiii
          _reviews.addAll(filteredDocs);
        }
      }

      setState(() {
        _hasMoreData = querySnapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchMoreReviews() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: widget.placeId);
      
      if (_selectedRatingFilter != null) {
        query = query.where('rating', isEqualTo: _selectedRatingFilter);
      }
      
      query = query.orderBy('timestamp', descending: _sortByNewest);
      
      query = query.startAfterDocument(_lastDocument!);

      QuerySnapshot querySnapshot = await query.limit(_limit).get();

      if (querySnapshot.docs.isNotEmpty) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final filteredDocs = querySnapshot.docs.where((doc) {
          return doc['userId'] != currentUserId;
        }).toList();
        
        if (filteredDocs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
          _reviews.addAll(filteredDocs);
        }
      }

      setState(() {
        _hasMoreData = querySnapshot.docs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _refreshData() async {
    setState(() {
      _reviews.clear();
      _lastDocument = null;
      _hasMoreData = true;
      _isLoading = false;
      _currentUserReview = null; 
    });
    await _fetchCurrentUserReview();
    await _fetchReviews();
  }
  void _applyFilters() {
    setState(() {
      _reviews.clear();
      _lastDocument = null;
      _hasMoreData = true;
      _isLoading = false;
    });
    _fetchReviews();
  }
  
  void _resetFilters() {
    setState(() {
      _selectedRatingFilter = null;
      _sortByNewest = true;
      _reviews.clear();
      _lastDocument = null;
      _hasMoreData = true;
      _isLoading = false;
    });
    _fetchReviews();
  }

  void _showFilterDialog() {
    int? tempRatingFilter = _selectedRatingFilter;
    bool tempSortByNewest = _sortByNewest;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.isDarkMode ? const Color(0xff292828) : Colors.white,
            title: Text(
              "Filter Reviews",
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rating",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                
                // Rating filter
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text("All"),
                      selected: tempRatingFilter == null,
                      selectedColor: Color(0xff98855A),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempRatingFilter = null;
                        });
                      },
                    ),
                    ...List.generate(5, (index) {
                      final rating = index + 1;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("$rating"),
                            Icon(Icons.star, size: 14, color: tempRatingFilter == rating ? Colors.white : Color(0xff98855A)),
                          ],
                        ),
                        selected: tempRatingFilter == rating,
                        selectedColor: Color(0xff98855A),
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setDialogState(() {
                            tempRatingFilter = selected ? rating : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
                
                SizedBox(height: 20),
                
                Text(
                  "Sort by",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                
                // Sort options
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text("Newest"),
                      selected: tempSortByNewest,
                      selectedColor: Color(0xff98855A),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempSortByNewest = true;
                        });
                      },
                    ),
                    FilterChip(
                      label: Text("Oldest"),
                      selected: !tempSortByNewest,
                      selectedColor: Color(0xff98855A),
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempSortByNewest = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: context.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedRatingFilter = null;
                    _sortByNewest = true;
                  });
                  _applyFilters();
                },
                child: Text(
                  "Reset",
                  style: TextStyle(
                    color: Colors.red[300],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedRatingFilter = tempRatingFilter;
                    _sortByNewest = tempSortByNewest;
                  });
                  _applyFilters();
                },
                child: Text(
                  "Apply",
                  style: TextStyle(
                    color: Color(0xff98855A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteReview(DocumentSnapshot review) {
    final data = review.data() as Map<String, dynamic>;
    final int reviewRating = data['rating'] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? const Color(0xff292828) : Colors.white,
        title: Text(
          "Delete Review",
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this review?",
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReview(review, reviewRating);
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red[300],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteReview(DocumentSnapshot review, int reviewRating) async {
    final String placeId = review['placeId'];
    final String userId = review['userId'];
    
    try {
      
      // detele review
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // get current place data
        final placeRef = FirebaseFirestore.instance.collection('allPlace').doc(placeId);
        final placeSnapshot = await transaction.get(placeRef);
        
        if (!placeSnapshot.exists) {
          throw Exception("Place document not found");
        }
        
        final placeData = placeSnapshot.data() as Map<String, dynamic>;
        final currentReviewCount = placeData['review'] ?? 0;
        final currentRating = placeData['rating'] ?? 0.0;
        
        
        // convert rating ke double
        final double currentRatingDouble = currentRating is int 
            ? currentRating.toDouble() 
            : currentRating;
        
        if (currentReviewCount <= 1) {
          // kalo ratingny siso 1 trus didelete jadiin 0
          transaction.update(placeRef, {
            'review': 0,
            'rating': 0.0,
          });
        } else {
          // itung ulang rating placeny
          final totalRatingPoints = currentRatingDouble * currentReviewCount;
          final newTotalRatingPoints = totalRatingPoints - reviewRating;
          final newReviewCount = currentReviewCount - 1;
          final newRating = newTotalRatingPoints / newReviewCount;
          
          
          transaction.update(placeRef, {
            'review': newReviewCount,
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
        }
        
        // Delete the review document
        transaction.delete(review.reference);
        
        // kurangin user review parameter
        final userRef = FirebaseFirestore.instance.collection('Users').doc(userId);
        transaction.update(userRef, {
          'reviews': FieldValue.increment(-1)
        });
      });
      
      
      _refreshData();
      
      // Notify parent screen 
      if (widget.onReviewDeleted != null) {
        widget.onReviewDeleted!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Success",
            message: "Review deleted successfully",
            contentType: ContentType.success,
            color: Color(0xff98855A),
          ),
        ),
      );
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Error",
            message: "Failed to delete review: $e",
            contentType: ContentType.failure,
            color: Colors.red,
          ),
        ),
      );
    }
  }

  Widget _buildReviewItem(DocumentSnapshot review) {
    final data = review.data() as Map<String, dynamic>;
    final comment = data['comment'] ?? '';
    final userId = data['userId'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final timeAgo = timestamp != null
        ? timeago.format(timestamp, locale: 'en_short')
        : 'recent';
    final rating = data['rating'] ?? 0;
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isUserReview = userId == currentUserId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
      builder: (context, snapshot) {
        String username = 'Anonymous';
        String profilePic = '';
        
        if (snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          username = userData?['name'] ?? 'Anonymous';
          profilePic = userData?['profilePicture'] ?? '';
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => profilePic.isNotEmpty ? _showFullImageDialog(profilePic) : null,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : null,
                      child: profilePic.isEmpty
                          ? Icon(Icons.person, size: 24, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isUserReview)
                    IconButton(
                      onPressed: () => _confirmDeleteReview(review),
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red[300],
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: index < rating ? Color(0xff98855A) : Colors.grey,
                        size: 18,
                      );
                    }),
                  ),
                ],
              ),
              SizedBox(height: 12),

              if (imageUrls.isNotEmpty)
                Container(
                  height: 120,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _showFullImageDialog(imageUrls[index]);
                        },
                        child: Container(
                          width: 120,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              Text(
                comment,
                style: TextStyle(
                  color: context.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Reviews for ${widget.placeName}',
          style: TextStyle(
            color: context.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.filter_list,
                  color: (_selectedRatingFilter != null || !_sortByNewest) 
                    ? Color(0xff98855A) 
                    : context.isDarkMode ? Colors.white : Colors.black,
                ),
                if (_selectedRatingFilter != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xff98855A),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$_selectedRatingFilter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Color(0xff98855A),
        child: Column(
          children: [
            if (_selectedRatingFilter != null || !_sortByNewest)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Filtered by: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    if (_selectedRatingFilter != null)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xff98855A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedRatingFilter}★',
                              style: TextStyle(
                                color: Color(0xff98855A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRatingFilter = null;
                                });
                                _applyFilters();
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xff98855A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_sortByNewest)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xff98855A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Oldest first',
                              style: TextStyle(
                                color: Color(0xff98855A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortByNewest = true;
                                });
                                _applyFilters();
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xff98855A),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            if (_currentUserReview != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xff98855A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "My Review",
                        style: TextStyle(
                          color: Color(0xff98855A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildReviewItem(_currentUserReview!),
                  ],
                ),
              ),
              
            Expanded(
              child: _reviews.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        _selectedRatingFilter != null 
                          ? 'No reviews with ${_selectedRatingFilter} star rating.' 
                          : 'No reviews yet.',
                        style: TextStyle(
                          color: context.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: _reviews.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _reviews.length) {
                          return _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff98855A)),
                                  ),
                                )
                              : SizedBox.shrink();
                        }
                        return _buildReviewItem(_reviews[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
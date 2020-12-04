# How to use SkyFeed data

1. Get the user id (Can be found in the URL when on a user page: `[...]/#/user/USERID`)
2. Fetch the `profile` datakey with the user id as public key

Example:
```json
{
   "username":"redsolver",
   "aboutMe":"Developer",
   "dapps":{
      "skyfeed":{
         "url":"https://skyfeed-beta.hns.siasky.net/",
         "publicKey":"5462ba9e866e4136f21e2fe0482d4a9fea7e8b52aa5a17141d9c4fe8cf381e8a",
         "img":null
      }
   },
   "location":"Germany",
   "avatar":"PAJVvjUPcCoDRmSUUL2kNigL4m58U3qnaKRX9Wr-XAp5lg"
}
```

3. Get the skyfeed public key from the `profile` JSON (`.dapps.skyfeed.publicKey`)
4. Fetch the `skyfeed-user` datakey using the new skyfeed public key (**everything skyfeed-related uses the skyfeed public key!**):

```json
{"feed/comments/position":3,"feed/posts/position":2}
```

SkyFeed uses the `posts` feed for posts and reposts which appear on the home and user page. The `comments` feed is used for comments.
Both feeds are organized using pages and everytime a single page fills up with 16 posts, a new page is created. The `position` in the `skyfeed-user` shows you what the current page is so you can directly load the latest content. If you want to get all content, the page index starts at `0` and goes `+1` on every new page.


5. Fetch followers and users being followed by a user using `skyfeed-following` and `skyfeed-followers`

Example for `skyfeed-followers`:
```json
{
   "54ee119b9bce2790c7a3baed1ddf968a32bab4d7710270acf85f28a9dac0e66a":{},
   "202f98e8a7baaa82b7003c716a1f76d07e8dacde5086197541a77c8ab1050015":{},
   "86939f3af93113fb5f11056828f7019e875a07190f5c4b07e90593f5d9929965":{},
   "d873ca08a7ffe36a8b19fa5d82cb34cfad70d2f0b3d5b1f2448a2054703e36d4":{}
}
```
The keys of this map are the user ids of people following/being followed (**These ids are NOT skyfeed public keys, they are Sky ID user ids! You need to fetch their `profile` like in 1. to get their skyfeed public key and load their skyfeed data!**).

6. Fetch a feed page using `skyfeed-feed/FEEDNAME/INDEX`
`FEEDNAME` can be `posts` or `comments`.

Example: `skyfeed-feed/posts/2`:
```json
{
   "$type":"feed",
   "userId":"d448f1562c20dbafa42badd9f88560cd1adb2f177b30f0aa048cb243e55d37bd",
   "items":[
      {
         "$type":"post",
         "id":0,
         "content":{
            "text":"SkyFeed is now open-source under the MIT license!",
            "link":"https://github.com/redsolver/skyfeed"
         },
         "ts":1606156338036
      },
      {
         "$type":"post",
         "id":1,
         "isDeleted":true
      },
      {
         "$type":"post",
         "id":2,
         "isDeleted":true
      },
      {
         "$type":"post",
         "id":3,
         "isDeleted":true
      },
      {
         "$type":"post",
         "id":4,
         "isDeleted":true
      },
      {
         "$type":"post",
         "id":5,
         "content":{
            "text":"",
            "image":"sia://_ATYunyHOwWQVvSEvXHGmI3lSlIFRbg_ZvtgvYhNpSyv3g",
            "aspectRatio":1.457858769931663,
            "blurHash":"L@L4$+00j@xuayjtfQayofayfQj[",
            "link":"https://www.reddit.com/r/memes/comments/j8xm2z/its_gif_saturday/"
         },
         "ts":1606169889148
      },
      {
         "$type":"post",
         "id":6,
         "repostOf":"5335179d69a3191ccb6329dcc0d2aaac2cada7ce145cbbd5543c8c2ee97e2a4a/feed/posts/0/11",
         "parentHash":"sha256:24126b48452ce0243ae0f6bd3a3e0f9ee06ac01d5dab557c365b3e1bb8972fa5",
         "ts":1606230164276
      },
      {
         "$type":"post",
         "id":7,
         "repostOf":"f2efbbbf95954059fe8f41b582ef128d105ef3ad4b31f6fa6055897c1de2ad22/feed/posts/0/0",
         "parentHash":"sha256:3c86e79b476ade11d2e39d2eaeaeed8c380200ad2d8ecf528308f995a23dc594",
         "ts":1606302965609
      },
      {
         "$type":"post",
         "id":8,
         "repostOf":"9d21deb0600b6a3a9bfd14c38a7b9b489bc3c959169dfe022e8d2180e2fd28c5/feed/posts/0/0",
         "parentHash":"sha256:263747fd86327cfbbef5cf27258d8da1d418dacc9806d500b72d7ddfc9ee41b6",
         "ts":1606375358014
      },
      {
         "$type":"post",
         "id":9,
         "repostOf":"d73c16c364606a83fd93777ad74b21cd32ca11729c8573fe6654973a8308d56c/feed/posts/0/10",
         "parentHash":"sha256:8984a4d3a14835d8020e3c8a9bac804d714109df8be7960bd2d27da881ad28cb",
         "ts":1606422542946
      },
      {
         "$type":"post",
         "id":10,
         "content":{
            "text":"Hi everyone, please let me know which of these features you would like to see the most on SkyFeed and why!\n\n1. Mention other users with @\n2. Handshake Username Verification\n3. Likes and/or Emoji Reactions\n4. Optional markdown support\n5. Custom color theme with sync and share functionality\n\nIf you have a feature request not listed here, please add it on GitHub!",
            "link":"https://github.com/redsolver/skyfeed/issues"
         },
         "ts":1606651550212
      },
      {
         "$type":"post",
         "id":11,
         "repostOf":"d228a077e7a1aa2a96a3be25c8713174ef46810a37a6c48b39b10624b574bbe6/feed/posts/0/0",
         "parentHash":"sha256:4271133138b60dac2da60e0b1f4780987817fc291356aa3d8c58ab17797d17ea",
         "ts":1606741888252
      },
      {
         "$type":"post",
         "id":12,
         "repostOf":"70a3fffccae8618b12f8878f94f118350717e363b143f1d5d8df787ffb1c9ae7/feed/posts/1/10",
         "parentHash":"sha256:f425ffc50a36a80f1f3c8b91b6f2e4a69a3f4a30ceef319a56c413c691fadd49",
         "ts":1606741899569
      }
   ]
}
```

## Anatomy of a full post id

Example: `f2efbbbf95954059fe8f41b582ef128d105ef3ad4b31f6fa6055897c1de2ad22/feed/posts/0/1`

`f2efbbbf95954059fe8f41b582ef128d105ef3ad4b31f6fa6055897c1de2ad22` is the userId (**NOT the skyfeed public key!**).
`feed` is the type.
`posts` is the feed.
`0` is the pageId.
`1` is the postId (`0-15` bound to the page).

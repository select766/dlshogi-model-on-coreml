# dlshogiのDNNモデルをiOSのCore MLで動作させる実験コード

計算結果の誤差の計算（PyTorchでの計算結果と比較）と、速度ベンチマーク機構のみが実装されている。

Xcodeでのビルド・実機転送が必要。

## ファイルの準備

モデルとテストデータは大きいので、リポジトリ内に入れていない。GithubのReleasesから取得して配置する必要がある。
`DlshogiOnCoreML/SampleIO.bin`, `DlshogiOnCoreML/Preview Content/DlShogiResnet10SwishBatch.mlmodel`の配置が必要。

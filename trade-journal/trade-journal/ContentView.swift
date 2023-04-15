import SwiftUI

struct Trade: Identifiable {
    let id = UUID()
    private var _ticker: String
    var ticker: String {
        get { _ticker }
        set { _ticker = newValue.uppercased() }
    }
    var tvh: Double = 0.0
    var sl: Double = 0.0
    var risk: Double {
        let risk = (abs(sl / tvh - 1) * 100).rounded(toPlaces: 2)
        return risk
    }
    
    init(ticker: String = "not_set", tvh: Double, sl: Double) {
        self._ticker = ticker.uppercased()
        self.tvh = tvh
        self.sl = sl
    }
}


class TradeStore: ObservableObject {
    @Published var trades: [Trade] = []
    var totalRisk: Double {
        return trades.reduce(0) { $0 + $1.risk }
    }
    func addTrade(_ trade: Trade) {
        trades.append(trade)
    }
    func deleteTrade(at offsets: IndexSet) {
        trades.remove(atOffsets: offsets)
    }
}

struct TradeListView: View {
    @EnvironmentObject var tradeStore: TradeStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tradeStore.trades) { trade in
                    TradeRowView(trade: trade)
                }
                .onDelete { offsets in
                    deleteTrade(at: offsets)
                }

            }
            .navigationBarTitle("Trades")
            .navigationBarItems(trailing:
                NavigationLink(destination: AddTradeView()) {
                    Image(systemName: "plus")
                }
            )
        }
    }
    
    private func deleteTrade(at offsets: IndexSet) {
        tradeStore.deleteTrade(at: offsets)
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(trade.ticker)
                .font(.headline)
            HStack {
                Text("TVH: \(trade.tvh, specifier: "%.2f")")
                Spacer()
                Text("SL: \(trade.sl, specifier: "%.2f")")
                Spacer()
                Text("Risk: \(String(format: "%.2f", abs(trade.risk)))%")
                    .foregroundColor(getRiskColor(trade.risk))
            }
        }
    }
    
    func getRiskColor(_ risk: Double) -> Color {
        if risk < 5 {
            return Color.green
        } else if risk >= 5 && risk < 15 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
}

struct AddTradeView: View {
    @EnvironmentObject var tradeStore: TradeStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var ticker = "not_ticker"
    @State private var tvhText = ""
    @State private var slText = ""
    
    var body: some View {
        Form {
            Section(header: Text("Trade Details")) {
                ZStack(alignment: .leading) {
                    if ticker.isEmpty {
                        Text("Ticker")
                            .foregroundColor(Color(.systemGray))
                    }
                    TextField("", text: $ticker)
                        .onAppear {
                            if ticker == "not_ticker" {
                                ticker = ""
                            }
                        }
                        .foregroundColor(.primary)
                }
                TextField("TVH", text: $tvhText)
                    .keyboardType(.decimalPad)
                TextField("SL", text: $slText)
                    .keyboardType(.decimalPad)
            }
            Section {
                Button("Save") {
                    guard !tvhText.isEmpty, !slText.isEmpty,
                          let tvh = Double(tvhText),
                          let sl = Double(slText) else {
                        return
                    }
                    if ticker.isEmpty {
                        ticker = "HDFS1000"
                    }
                    let trade = Trade(ticker: ticker.uppercased(), tvh: tvh, sl: sl)
                    tradeStore.addTrade(trade)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitle("Add Trade")
    }
}




struct ContentView: View {
    var body: some View {
        TradeListView()
            .environmentObject(TradeStore())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

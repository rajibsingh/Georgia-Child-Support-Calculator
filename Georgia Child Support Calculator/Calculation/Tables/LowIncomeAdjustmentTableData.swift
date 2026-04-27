import Foundation

enum LowIncomeAdjustmentTableData {
    static let version = StatutoryTableVersion(
        effectiveDate: "2026-01-01",
        source: "O.C.G.A. § 19-6-15(p) Low-income Adjustment Table"
    )

    static let atOrBelow1500Percentages: [Int: Decimal] = [
        1: Decimal(string: "0.19")!,
        2: Decimal(string: "0.24")!,
        3: Decimal(string: "0.25")!,
        4: Decimal(string: "0.26")!,
        5: Decimal(string: "0.27")!,
        6: Decimal(string: "0.28")!
    ]

    static let rows: [LowIncomeAdjustmentRow] = [
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1550, capsDollars: [295, 372, 388, 403, 419, 434]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1600, capsDollars: [304, 389, 408, 427, 444, 462]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1650, capsDollars: [314, 405, 429, 450, 470, 490]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1700, capsDollars: [323, 422, 450, 474, 496, 518]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1750, capsDollars: [333, 439, 471, 497, 522, 546]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1800, capsDollars: [342, 456, 492, 521, 548, 574]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1850, capsDollars: [352, 472, 513, 544, 574, 601]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1900, capsDollars: [361, 489, 534, 568, 599, 629]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 1950, capsDollars: [371, 506, 555, 591, 625, 657]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2000, capsDollars: [381, 522, 576, 615, 651, 685]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2050, capsDollars: [390, 539, 597, 638, 677, 713]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2100, capsDollars: [400, 556, 618, 662, 703, 741]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2150, capsDollars: [409, 573, 639, 685, 729, 769]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2200, capsDollars: [419, 589, 660, 709, 754, 797]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2250, capsDollars: [428, 606, 681, 732, 780, 825]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2300, capsDollars: [438, 623, 702, 756, 806, 853]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2350, capsDollars: [448, 639, 723, 779, 832, 881]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2400, capsDollars: [457, 656, 744, 803, 858, 909]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2450, capsDollars: [467, 673, 765, 826, 884, 936]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2500, capsDollars: [nil, 690, 786, 850, 910, 964]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2550, capsDollars: [nil, 706, 807, 873, 935, 992]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2600, capsDollars: [nil, 723, 828, 897, 961, 1020]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2650, capsDollars: [nil, 740, 848, 920, 987, 1048]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2700, capsDollars: [nil, 756, 869, 944, 1013, 1076]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2750, capsDollars: [nil, 773, 890, 967, 1039, 1104]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2800, capsDollars: [nil, 790, 911, 991, 1065, 1132]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2850, capsDollars: [nil, 807, 932, 1014, 1090, 1160]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2900, capsDollars: [nil, 823, 953, 1038, 1116, 1188]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 2950, capsDollars: [nil, 840, 974, 1061, 1142, 1216]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3000, capsDollars: [nil, nil, 995, 1085, 1168, 1243]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3050, capsDollars: [nil, nil, 1016, 1108, 1194, 1271]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3100, capsDollars: [nil, nil, 1037, 1132, 1220, 1299]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3150, capsDollars: [nil, nil, 1058, 1155, 1245, 1327]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3200, capsDollars: [nil, nil, 1079, 1179, 1271, 1355]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3250, capsDollars: [nil, nil, 1100, 1202, 1297, 1383]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3300, capsDollars: [nil, nil, 1121, 1226, 1323, 1411]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3350, capsDollars: [nil, nil, 1142, 1249, 1349, 1439]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3400, capsDollars: [nil, nil, nil, 1273, 1375, 1467]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3450, capsDollars: [nil, nil, nil, 1296, 1401, 1495]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3500, capsDollars: [nil, nil, nil, 1320, 1426, 1523]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3550, capsDollars: [nil, nil, nil, 1343, 1452, 1550]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3600, capsDollars: [nil, nil, nil, nil, 1478, 1578]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3650, capsDollars: [nil, nil, nil, nil, 1504, 1606]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3700, capsDollars: [nil, nil, nil, nil, 1530, 1634]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3750, capsDollars: [nil, nil, nil, nil, 1556, 1662]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3800, capsDollars: [nil, nil, nil, nil, nil, 1690]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3850, capsDollars: [nil, nil, nil, nil, nil, 1718]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3900, capsDollars: [nil, nil, nil, nil, nil, 1746]),
        LowIncomeAdjustmentRow(adjustedIncomeDollars: 3950, capsDollars: [nil, nil, nil, nil, nil, 1774])
    ]
}

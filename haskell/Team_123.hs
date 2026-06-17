data Month = Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec   deriving (Show, Eq)

type Date = (Int, Month, Int)
type Price = Float
type Quantity = Int

type Supply = (String, Quantity, Price)
--	representing the name of the ingredient, quantity needed of that ingredient, and the total price of the needed quantity

type Delivery = (Date, [Supply])
-- date of delivery the restaurant will make and the required supply on that date.


data Ingredient =
    SimpleIngredient String  -- A basic ingredient
  | Recipe String [Ingredient] deriving (Show, Eq)
  -- An ingredient consisting of other ingredients


data Expense =
    Item String Price Date
    -- A single expense item
  | Category String [Expense]
  -- A category of expenses that could contain expenses or other categories.
  deriving (Show, Eq)


ingredient_info :: [(String, Int, Price)]
ingredient_info = [("rice", 20, 1.2), ("apples", 5, 5), ("flour", 1, 0.5), ("eggs",1, 2), ("butter", 3, 12), ("garlic", 11, 4.5), ("salt", 0,0.25), ("pepper", 66,0.75), ("sugar", 7, 6), ("goat_meat", 20, 1.2)]

shopping_list :: [(Date, [Ingredient])]
shopping_list = [((15,Feb,2026),
                    [SimpleIngredient "flour",
                     SimpleIngredient "eggs",
                     SimpleIngredient "rice"]),
                 ((17,Feb,2026),
                    [SimpleIngredient "sugar",
                     SimpleIngredient "butter",
                     SimpleIngredient "flour",
                     SimpleIngredient "flour",
                     (Recipe "dough" [(SimpleIngredient "flour"),
                                      (SimpleIngredient "eggs")])]),
                 ((5,Mar,2026),
                    [SimpleIngredient "salt",
                     SimpleIngredient "pepper",
                     SimpleIngredient "garlic"]) ]

monthNum :: Month -> Int
monthNum Jan = 1
monthNum Feb = 2
monthNum Mar = 3
monthNum Apr = 4
monthNum May = 5
monthNum Jun = 6
monthNum Jul = 7
monthNum Aug = 8
monthNum Sep = 9
monthNum Oct = 10
monthNum Nov = 11
monthNum Dec = 12

previousMonth :: Month -> Month
previousMonth Jan = Dec
previousMonth Feb = Jan
previousMonth Mar = Feb
previousMonth Apr = Mar
previousMonth May = Apr
previousMonth Jun = May
previousMonth Jul = Jun
previousMonth Aug = Jul
previousMonth Sep = Aug
previousMonth Oct = Sep
previousMonth Nov = Oct
previousMonth Dec = Nov

monthDays :: Month -> Int
monthDays Jan = 31
monthDays Feb = 28
monthDays Mar = 31
monthDays Apr = 30
monthDays May = 31
monthDays Jun = 30
monthDays Jul = 31
monthDays Aug = 31
monthDays Sep = 30
monthDays Oct = 31
monthDays Nov = 30
monthDays Dec = 31

subtractDays :: Date -> Int -> Date
subtractDays (d, m, y) 0 = (d, m, y)
subtractDays (d, m, y) n
    | n < d     = (d - n, m, y)
    | otherwise = subtractDays (monthDays pm, pm, py) (n - d)
    where
        pm = previousMonth m
        py = if m == Jan then y - 1 else y

dateOrder :: Date -> Date -> Ordering
dateOrder (d1, m1, y1) (d2, m2, y2)
    | y1 /= y2             = compare y1 y2
    | monthNum m1 /= monthNum m2 = compare (monthNum m1) (monthNum m2)
    | otherwise            = compare d1 d2

insertSorted :: (a -> a -> Bool) -> a -> [a] -> [a]
insertSorted _ x [] = [x]
insertSorted isLess x (y:ys)
    | isLess x y = x : y : ys
    | otherwise  = y : insertSorted isLess x ys

sortWith :: (a -> a -> Bool) -> [a] -> [a]
sortWith isLess xs = foldr (insertSorted isLess) [] xs

removeDups :: Eq a => [a] -> [a]
removeDups [] = []
removeDups (x:xs) = x : removeDups (filter (/= x) xs)

getIngredientInfo :: String -> (Int, Price)
getIngredientInfo name = search ingredient_info
    where
        search [] = (0, 0.0)
        search ((n, days, price):rest)
            | n == name = (days, price)
            | otherwise = search rest

lookupIngredients :: Date -> [Ingredient]
lookupIngredients d = search shopping_list
    where
        search [] = []
        search ((date, ings):rest)
            | d == date = ings
            | otherwise = search rest

countAllLeaves :: Expense -> Int
countAllLeaves (Item _ _ _)      = 1
countAllLeaves (Category _ exps) = sum (map countAllLeaves exps)

calculateDeliveryDates :: Date -> [Ingredient] -> [(Date, (String, Price))]
calculateDeliveryDates _ [] = []
calculateDeliveryDates date (SimpleIngredient name : rest) =
    (subtractDays date days, (name, price)) : calculateDeliveryDates date rest
    where
        (days, price) = getIngredientInfo name
calculateDeliveryDates date (Recipe _ subIngs : rest) =
    calculateDeliveryDates date subIngs ++ calculateDeliveryDates date rest

summarizeAllDeliveries :: [Date] -> [Delivery]
summarizeAllDeliveries dates = sortWith deliveryLess (map buildEntry uniqueDates)
    where
        allEntries = concatMap getEntries dates
        getEntries d = map unpack (calculateDeliveryDates d (lookupIngredients d))
        unpack (dd, (n, p)) = (dd, n, p)

        getDate (d, _, _) = d
        uniqueDates = removeDups (map getDate allEntries)
        deliveryLess (d1, _) (d2, _) = dateOrder d1 d2 == LT

        buildEntry dd = (dd, sortWith nameLess (map aggregate uniqueNames))
            where
                forThisDate = [(n, p) | (d, n, p) <- allEntries, d == dd]
                uniqueNames = removeDups (map fst forThisDate)
                nameLess a b = a < b

                aggregate name = (name, qty, totalCost)
                    where
                        prices    = [p | (n, p) <- forThisDate, n == name]
                        qty       = length prices
                        totalCost = fromIntegral qty * head prices

getDeliveryExpenses :: [Delivery] -> Expense
getDeliveryExpenses deliveries = Category "Food Supplies" (concatMap makeItems deliveries)
    where
        makeItems (date, supplies) = map (toExpense date) supplies
        toExpense date (name, _, price) = Item name price date

mostPopularDish :: [String] -> [String]
mostPopularDish [] = []
mostPopularDish dishes = filter (\d -> countOccurrences d == topCount) unique
    where
        unique = removeDups dishes
        countOccurrences d = length (filter (== d) dishes)
        topCount = maximum (map countOccurrences unique)

calculateTotalExpenses :: Expense -> Price
calculateTotalExpenses (Item _ price _)  = price
calculateTotalExpenses (Category _ exps) = sum (map calculateTotalExpenses exps)

countCategoryItems :: String -> Expense -> Int
countCategoryItems _ (Item _ _ _) = 0
countCategoryItems target (Category name exps)
    | target == name = countAllLeaves (Category name exps)
    | otherwise      = sum (map (countCategoryItems target) exps)

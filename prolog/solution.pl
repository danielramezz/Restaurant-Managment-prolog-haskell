:- consult('sample_KB.pl').
:- use_module(library(lists)).

count_res(_, _, [], 0).

count_res(Day, Time, [res(Day, Time, _, _)|T], N) :-
    !,
    count_res(Day, Time, T, N1),
    N is N1 + 1.

count_res(Day, Time, [_|T], N) :-
    count_res(Day, Time, T, N).

check_staff(Day, Time, Rs) :-
    staff(Day, S),
    count_res(Day, Time, Rs, C),
    C =< S.

schedule_all_reservations(Days, Schedule) :-
    findall(G, group(G, _, _), Groups),
    assign_groups(Groups, Days, [], Schedule).

assign_groups([], _, Acc, Acc).

assign_groups([G|Rest], Days, Acc, Schedule) :-
    group(G, Size, Time),
    member(Day, Days),
    tables(Ts),
    member(t(Table, Cap), Ts),
    Cap >= Size,
    \+ member(res(Day, Time, _, Table), Acc),
    R = res(Day, Time, G, Table),
    check_staff(Day, Time, [R|Acc]),
    assign_groups(Rest, Days, [R|Acc], Schedule).

dishes_ingredients([], []).

dishes_ingredients([D|Rest], Ings) :-
    recipe(D, DI),
    dishes_ingredients(Rest, RI),
    append(DI, RI, Ings).

group_ingredients(G, Ings) :-
    order(G, Dishes),
    dishes_ingredients(Dishes, Ings).

groups_ingredients([], []).

groups_ingredients([G|Rest], Ings) :-
    group_ingredients(G, GI),
    groups_ingredients(Rest, RI),
    append(GI, RI, Ings).

needed_ingredients(Rs, All) :-
    findall(Day, member(res(Day, _, _, _), Rs), Days),
    sort(Days, UniDays),
    days_ingredients(UniDays, Rs, All).

days_ingredients([], _, []).

days_ingredients([Day|Rest], Rs, [(Day, Ings)|T]) :-
    findall(G, member(res(Day, _, G, _), Rs), Groups),
    groups_ingredients(Groups, Ings),
    days_ingredients(Rest, Rs, T).

write_reservations_to_csv(File, Schedule) :-
    open(File, write, S),
    format(S, 'Day,Month,Time,Group,Table~n', []),
    write_res_rows(S, Schedule),
    close(S).

write_res_rows(_, []).

write_res_rows(S, [res(day(D, M), Time, G, Table)|Rest]) :-
    format(S, '~w,~w,~w,~w,~w~n', [D, M, Time, G, Table]),
    write_res_rows(S, Rest).

write_ingredients_to_csv(File, All) :-
    open(File, write, S),
    format(S, 'Day,Month,Ingredients~n', []),
    write_ing_rows(S, All),
    close(S).

write_ing_rows(_, []).

write_ing_rows(S, [(day(D, M), Ings)|Rest]) :-
    atomic_list_concat(Ings, ';', IngStr),
    format(S, '~w,~w,~w~n', [D, M, IngStr]),
    write_ing_rows(S, Rest).

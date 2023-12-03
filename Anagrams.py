def anagrams(text):
    anagram_list=[]
    for word in text:
        for word_2 in text:
            if word != word_2 and (sorted(word)==sorted(word_2)):
                anagram_list.append(word)
    print(anagram_list)






word_list = ["percussion", "supersonic", "car", "tree", "boy", "girl", "arc"]
anagrams(word_list)
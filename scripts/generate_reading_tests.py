#!/usr/bin/env python3
import json
import os

# We will preserve the two existing tests and add 18 new full-scale authentic tests
tests = [
  # 1. The Importance of Law
  {
    "id": "READING-1516",
    "title": "The Importance of Law",
    "topic": "Society & Legal Systems",
    "category": "Recent Actual Tests",
    "estimated_minutes": 20,
    "paragraphs": {
      "A": "The law influences all of us virtually all the time. It governs almost all aspects of our behavior, and even what happens to us when we are no longer alive. It affects us from the embryo onwards. It governs the air we breathe, the food and drink we consume, our travel, family relationships, and our property. It applies at the bottom of the ocean and in space. Each time we examine a label on a food product, engage in work as an employee or employer, travel on the roads, go to school to learn or to teach, stay in a hotel, borrow a library book, create or dissolve a commercial company, play sports, or engage the services of someone for anything from plumbing a sink to planning a city, we are in the world of law.",
      "B": "Law has also become much more widely recognised as the standard by which behavior needs to be judged. A very telling development in recent history is the way in which the idea of law has permeated all parts of social life. The universal standard of whether something is socially tolerated is progressively becoming whether it is legal, rather than something that has always been considered acceptable. In earlier times, most people were illiterate. Today, by contrast, a vast number of people can read, and it is becoming easier for people to take an interest in law, and for the general population to help actually shape the law in many countries. However, law is a versatile instrument that can be used equally well for the improvement or the degradation of humanity.",
      "C": "This, of course, puts law in a very significant position. In our rapidly developing world, all sorts of skills and knowledge are valuable. Those people, for example, with knowledge of computers, the internet, and communications technology are relied upon by the rest of us. There is now someone with IT skills or an IT help desk in every UK school, every company, every hospital, every local and central government office. Without their knowledge, many parts of commercial and social life today would seize up in minutes. But legal understanding is just as vital and as universally needed. The American comedian Jerry Seinfeld put it like this: 'We are all throwing the dice, playing the game, moving our pieces around the board, but if there is a problem, the lawyer is the only person who has read the inside of the top of the box.' In other words, the lawyer is the only person who has read and made sense of the rules.",
      "D": "The number of laws has never been greater. In the UK alone, about 35 new Acts of Parliament are produced every year, thereby delivering thousands of new rules. The legislative output of the British Parliament has more than doubled in recent times from 1,100 pages a year in the early 1970s to over 2,500 pages a year today. Between 1997 and 2006, the legislature passed 365 Acts of Parliament and more than 32,000 legally binding statutory instruments. In a system with so much law, lawyers do a great deal not just to vindicate the rights of citizens and organizations, but also to help develop the law through legal arguments, some of which are adapted by judges to become laws. Law courts can and do produce new law and revise old law, but they do so having heard the arguments of lawyers.",
      "E": "However, despite their important role in developing the rules, lawyers are not universally admired. Anti-lawyer jokes have a long history going back to the ancient Greeks. More recently, the son of a famous Hollywood actor was asked at his junior school what his father did for a living, to which he replied, 'My daddy is a movie actor, and sometimes he plays the good guy, and sometimes he plays the lawyer.' For balance, though, it is worth remembering that there are and have been many heroic and revered lawyers, such as the Roman philosopher and politician Cicero, and Mahatma Gandhi, the Indian campaigner for independence.",
      "F": "People sometimes make comments that characterise lawyers as professionals whose concerns put personal reward above truth, or who gain financially from misfortune. There are undoubtedly lawyers that would fit that bill, just as there are some scientists, journalists and others in that category. But, in general, it is no more just to say that lawyers are bad because they make a living from people's problems than it is to make the same accusation in respect of nurses or IT consultants. A great many lawyers are involved in public interest law and civil liberties work that requires considerable professional dedication. Moreover, a great deal of everyday legal work consists of drafting agreements and documents to prevent disputes before they can arise."
    },
    "questions": [
      {
        "number": 1,
        "type": "true_false_not_given",
        "prompt": "The law affects human beings even before they are born.",
        "accepted_answers": ["TRUE", "T"],
        "evidence_paragraph": "Paragraph A",
        "explanation": "Paragraph A states: 'It affects us from the embryo onwards.'"
      },
      {
        "number": 2,
        "type": "true_false_not_given",
        "prompt": "In the past, societal acceptance was largely based on written law rather than tradition.",
        "accepted_answers": ["FALSE", "F"],
        "evidence_paragraph": "Paragraph B",
        "explanation": "Paragraph B explains that the universal standard is progressively becoming whether something is legal, 'rather than something that has always been considered acceptable'."
      },
      {
        "number": 3,
        "type": "true_false_not_given",
        "prompt": "The general public has more influence on legislation now than in ancient times.",
        "accepted_answers": ["TRUE", "T"],
        "evidence_paragraph": "Paragraph B",
        "explanation": "Paragraph B contrasts earlier times when people were illiterate with today, where 'it is becoming easier for people to take an interest in law, and for the general population to help actually shape the law'."
      },
      {
        "number": 4,
        "type": "true_false_not_given",
        "prompt": "Jerry Seinfeld trained as a lawyer before becoming a famous comedian.",
        "accepted_answers": ["NOT GIVEN", "NG"],
        "evidence_paragraph": "Paragraph C",
        "explanation": "Paragraph C quotes Seinfeld using an analogy about board games, but makes no mention of his personal education or career background."
      },
      {
        "number": 5,
        "type": "true_false_not_given",
        "prompt": "Judges in the UK never create or modify laws independently of lawyers' arguments.",
        "accepted_answers": ["TRUE", "T"],
        "evidence_paragraph": "Paragraph D",
        "explanation": "Paragraph D states: 'Law courts can and do produce new law and revise old law, but they do so having heard the arguments of lawyers.'"
      },
      {
        "number": 6,
        "type": "true_false_not_given",
        "prompt": "Mahatma Gandhi gave up practicing law completely after entering politics.",
        "accepted_answers": ["NOT GIVEN", "NG"],
        "evidence_paragraph": "Paragraph E",
        "explanation": "Paragraph E mentions Gandhi as a revered lawyer and campaigner for independence, but does not state whether he completely stopped practicing law."
      },
      {
        "number": 7,
        "type": "multiple_choice",
        "prompt": "Jerry Seinfeld's board game analogy in Paragraph C is used to illustrate that:",
        "options": [
          "A) Lawyers are more intelligent than IT consultants",
          "B) Only lawyers understand the comprehensive framework of rules",
          "C) Modern legal disputes are like frivolous board games",
          "D) Society relies too heavily on legal intervention"
        ],
        "accepted_answers": ["B", "B) Only lawyers understand the comprehensive framework of rules"],
        "evidence_paragraph": "Paragraph C",
        "explanation": "Paragraph C concludes the quote with: 'In other words, the lawyer is the only person who has read and made sense of the rules.'"
      },
      {
        "number": 8,
        "type": "multiple_choice",
        "prompt": "According to Paragraph D, between 1997 and 2006, the British Parliament enacted:",
        "options": [
          "A) 2,500 new statutory instruments",
          "B) Over 32,000 legally binding statutory instruments",
          "C) 1,100 pages of statutory rules",
          "D) 35 statutory instruments per year"
        ],
        "accepted_answers": ["B", "B) Over 32,000 legally binding statutory instruments"],
        "evidence_paragraph": "Paragraph D",
        "explanation": "Paragraph D explicitly states: 'Between 1997 and 2006, the legislature passed 365 Acts of Parliament and more than 32,000 legally binding statutory instruments.'"
      },
      {
        "number": 9,
        "type": "fill_in_blank",
        "prompt": "Some critics claim that financial benefit matters more to lawyers than the ______ itself.",
        "accepted_answers": ["law", "the law", "truth", "the truth"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F notes comments that characterise lawyers as professionals 'whose concerns put personal reward above truth'."
      },
      {
        "number": 10,
        "type": "fill_in_blank",
        "prompt": "Criticizing lawyers for earning a living from societal difficulties is as unfair as targeting ______ or IT consultants.",
        "accepted_answers": ["nurses", "scientists"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F states: 'it is no more just to say that lawyers are bad because they make a living from people's problems than it is to make the same accusation in respect of nurses or IT consultants'."
      },
      {
        "number": 11,
        "type": "fill_in_blank",
        "prompt": "In addition to nurses, another profession compared in Paragraph F to show unfair public blame is ______.",
        "accepted_answers": ["IT consultants", "consultants", "scientists", "journalists"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F explicitly mentions 'nurses or IT consultants' as parallel professions."
      },
      {
        "number": 12,
        "type": "fill_in_blank",
        "prompt": "Lawyers handling civil liberties and public interest cases require substantial professional ______.",
        "accepted_answers": ["dedication"],
        "word_limit": 1,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F directly states that public interest work 'requires considerable professional dedication'."
      },
      {
        "number": 13,
        "type": "fill_in_blank",
        "prompt": "A major part of routine legal practice involves preparing agreements and ______ to avoid future conflict.",
        "accepted_answers": ["documents"],
        "word_limit": 1,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F explains: 'everyday legal work consists of drafting agreements and documents to prevent disputes before they can arise.'"
      }
    ]
  },
  # 2. The Dingo Debate
  {
    "id": "READING-1540",
    "title": "The Dingo Debate",
    "topic": "Wildlife & Conservation",
    "category": "Science & Environment",
    "estimated_minutes": 20,
    "paragraphs": {
      "A": "The dingo, Australia's native apex predator, has been an iconic yet intensely polarizing figure in the country's ecological history. Arriving approximately 4,000 years ago, likely introduced by Asian seafaring traders, the dingo quickly established itself across mainland Australia. For thousands of years, it coexisted with Indigenous Australians as a hunting companion and spiritual figure. However, the arrival of European pastoralists in the late 18th century transformed the dingo from a respected native carnivore into a despised agricultural pest.",
      "B": "The primary tension stems from predation on commercial livestock, particularly domestic sheep and young calves. In response to mounting livestock losses during the late 19th century, Australian pastoralists erected the famous Dingo Fence. Stretching over 5,600 kilometers from Queensland through South Australia, it remains one of the longest man-made structures in the world. Its purpose was unequivocal: to exclude dingoes from the fertile pastoral lands of south-eastern Australia and protect the wool and beef industries.",
      "C": "While the fence succeeded in suppressing dingo populations south of the barrier, modern ecologists argue that it inadvertently triggered profound trophic cascades. Without dingoes acting as top-order apex predators, populations of mesopredators—primarily the introduced red fox and feral cat—surged unchecked. These smaller predators have exerted devastating pressure on small-to-medium native marsupials, contributing directly to Australia having one of the worst mammal extinction records on Earth.",
      "D": "Furthermore, the absence of dingoes has led to explosive surges in native and feral herbivore populations, including red kangaroos and feral goats. These herbivores cause severe overgrazing, stripping semi-arid soil of perennial native grasses and accelerating desertification and land degradation. North of the Dingo Fence, where dingoes remain relatively abundant, vegetation cover is notably denser and small rodent diversity is measurably higher.",
      "E": "A further biological complication is the hybridization between pure dingoes and modern domestic dogs. Genetic surveys indicate that in south-eastern Australia, pure dingo genetics have been substantially diluted. Many farmers argue that hybrids and wild dogs lack the natural wariness of pure dingoes and pose an even greater threat to livestock. In contrast, conservation biologists advocate for recognizing pure dingoes as a threatened native taxon that warrants formal legal preservation.",
      "F": "Today, rewilding initiatives and predator-friendly farming methods are gaining traction among progressive graziers. Some pastoralists have successfully replaced indiscriminate poison-baiting (using compound 1080) with livestock guardian animals, such as Maremma sheepdogs or alpacas. These guard animals deter dingoes without eradicating them, enabling apex predators to continue regulating destructive feral foxes and kangaroo numbers while keeping sheep safe."
    },
    "questions": [
      {
        "number": 1,
        "type": "true_false_not_given",
        "prompt": "Dingoes were first brought to Australia by European explorers in the 18th century.",
        "accepted_answers": ["FALSE", "F"],
        "evidence_paragraph": "Paragraph A",
        "explanation": "Paragraph A states they arrived approximately 4,000 years ago, likely introduced by Asian seafaring traders, long before European arrival."
      },
      {
        "number": 2,
        "type": "true_false_not_given",
        "prompt": "The Dingo Fence stretches across more than 5,000 kilometers of Australian territory.",
        "accepted_answers": ["TRUE", "T"],
        "evidence_paragraph": "Paragraph B",
        "explanation": "Paragraph B confirms it stretches 'over 5,600 kilometers from Queensland through South Australia'."
      },
      {
        "number": 3,
        "type": "true_false_not_given",
        "prompt": "The construction of the Dingo Fence received unanimous support from 19th-century scientists.",
        "accepted_answers": ["NOT GIVEN", "NG"],
        "evidence_paragraph": "Paragraph B",
        "explanation": "Paragraph B mentions pastoralists erected the fence, but gives no information regarding whether 19th-century scientists supported or opposed it."
      },
      {
        "number": 4,
        "type": "true_false_not_given",
        "prompt": "In areas without dingoes, populations of red foxes and feral cats expanded rapidly.",
        "accepted_answers": ["TRUE", "T"],
        "evidence_paragraph": "Paragraph C",
        "explanation": "Paragraph C states: 'populations of mesopredators—primarily the introduced red fox and feral cat—surged unchecked'."
      },
      {
        "number": 5,
        "type": "true_false_not_given",
        "prompt": "Vegetation cover is sparser north of the Dingo Fence compared to the south.",
        "accepted_answers": ["FALSE", "F"],
        "evidence_paragraph": "Paragraph D",
        "explanation": "Paragraph D explicitly states: 'North of the Dingo Fence, where dingoes remain relatively abundant, vegetation cover is notably denser'."
      },
      {
        "number": 6,
        "type": "true_false_not_given",
        "prompt": "Maremma sheepdogs have completely replaced compound 1080 across all Australian farms.",
        "accepted_answers": ["FALSE", "F"],
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F states 'some pastoralists' have adopted guardian animals, not that it has completely replaced baiting nationwide."
      },
      {
        "number": 7,
        "type": "multiple_choice",
        "prompt": "What is described in Paragraph C as a major consequence of eliminating dingoes?",
        "options": [
          "A) A decline in wool exports from south-eastern Australia",
          "B) Disruption of the food web leading to higher native mammal extinctions",
          "C) Increased competition between cattle and domestic dogs",
          "D) Rapid spread of infectious diseases among sheep"
        ],
        "accepted_answers": ["B", "B) Disruption of the food web leading to higher native mammal extinctions"],
        "evidence_paragraph": "Paragraph C",
        "explanation": "Paragraph C details trophic cascades where fox and cat predation caused devastating pressure on small-to-medium native marsupials."
      },
      {
        "number": 8,
        "type": "multiple_choice",
        "prompt": "According to Paragraph E, why do some farmers consider hybrid wild dogs especially dangerous?",
        "options": [
          "A) They reproduce twice as quickly as pure dingoes",
          "B) They are immune to standard chemical poison baits",
          "C) They lack the innate caution of pure dingoes",
          "D) They hunt in packs much larger than native dingoes"
        ],
        "accepted_answers": ["C", "C) They lack the innate caution of pure dingoes"],
        "evidence_paragraph": "Paragraph E",
        "explanation": "Paragraph E states farmers argue that 'hybrids and wild dogs lack the natural wariness of pure dingoes'."
      },
      {
        "number": 9,
        "type": "fill_in_blank",
        "prompt": "Dingoes first arrived in Australia an estimated ______ years ago.",
        "accepted_answers": ["4,000", "4000", "four thousand"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph A",
        "explanation": "Paragraph A states: 'Arriving approximately 4,000 years ago'."
      },
      {
        "number": 10,
        "type": "fill_in_blank",
        "prompt": "The primary goal of building the Dingo Fence was to safeguard the beef and ______ sectors.",
        "accepted_answers": ["wool"],
        "word_limit": 1,
        "evidence_paragraph": "Paragraph B",
        "explanation": "Paragraph B states the objective was to 'protect the wool and beef industries'."
      },
      {
        "number": 11,
        "type": "fill_in_blank",
        "prompt": "Unchecked herbivore populations accelerate soil erosion and lead to ______.",
        "accepted_answers": ["desertification", "land degradation"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph D",
        "explanation": "Paragraph D states overgrazing leads to 'accelerating desertification and land degradation'."
      },
      {
        "number": 12,
        "type": "fill_in_blank",
        "prompt": "Indiscriminate poison-baiting in Australia commonly uses a chemical compound called ______.",
        "accepted_answers": ["1080", "compound 1080"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F mentions 'poison-baiting (using compound 1080)'."
      },
      {
        "number": 13,
        "type": "fill_in_blank",
        "prompt": "Some farmers now protect their herds by introducing guardian animals such as alpacas or ______.",
        "accepted_answers": ["Maremma sheepdogs", "sheepdogs", "guard dogs"],
        "word_limit": 2,
        "evidence_paragraph": "Paragraph F",
        "explanation": "Paragraph F specifies 'livestock guardian animals, such as Maremma sheepdogs or alpacas'."
      }
    ]
  }
]

print("Base tests loaded:", len(tests))

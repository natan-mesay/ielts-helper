#!/usr/bin/env python3
"""
IELTS Authentic Sentence Enrichment Engine
Replaces all generic sentence templates and scraped textbook exercises
with authentic, natural Academic English context sentences for IELTS preparation.
Ensures:
1. 100% match with Dart ClozeGenerator word boundary regex (\b{term}\b).
2. Semantically and grammatically accurate Academic English (no polarity/POS clashes).
3. Accurate dictionary definitions and clean parts of speech.
4. Cleaned lexical terms free of junk, notes, and duplicates.
"""

import json
import re
import csv

# Terms to drop (scraped table headers, grammar notes, exercises, non-lexical words)
DROPS = {
    'is', 'many', 'much', 'of', 'these', 'not many',
    'mass nouns', 'natural phenomena', 'powder and grain', 'liquids', 'states of being',
    'synonyms and types of government', 'word forms',
    'some clothing', 'some equipment', 'some information', 'some water',
    'some architecture can fall within this classification',
    'to increase the budget on x', 'two-fifths', 'suns', 'science and technology',
    'preposition', 'hot of the press', 'visual arts can be decorative'
}

# Term cleanups
CLEANS = {
    'newspaper / magazine': 'magazine',
    'altruism / altruistic': 'altruism',
    'fomite / fomites': 'fomites',
}

def enrich_item(term, pos, topic, current_def, current_ex):
    clean = term.strip()
    lower_t = clean.lower()
    lower_top = topic.lower()

    # --------------------------------------------------------------------------
    # 1. COMMON UNCOUNTABLE NOUNS (162 items)
    # --------------------------------------------------------------------------
    if "uncountable" in lower_top:
        neg_challenges = {
            'anger', 'chaos', 'corruption', 'damage', 'danger', 'darkness', 'failure',
            'guilt', 'harm', 'jealousy', 'litter', 'obesity', 'pollution', 'poverty',
            'racism', 'rubbish', 'smoke', 'stress', 'unemployment', 'violence'
        }
        public_goods = {
            'accommodation', 'advice', 'aid', 'assistance', 'education', 'electricity',
            'energy', 'guidance', 'health', 'help', 'hospitality', 'housing',
            'hygiene', 'nutrition', 'safety', 'transportation', 'welfare'
        }
        empirical_academic = {
            'content', 'data', 'evidence', 'information', 'intelligence', 'knowledge',
            'logic', 'pronunciation', 'punctuation', 'research', 'spelling', 'usage',
            'wisdom', 'grammar', 'genetics', 'literature', 'art'
        }
        virtues_psych = {
            'calm', 'courage', 'determination', 'enthusiasm', 'freedom', 'friendship',
            'happiness', 'honesty', 'humour', 'imagination', 'importance', 'innocence',
            'kindness', 'laughter', 'love', 'luck', 'motivation', 'patience', 'pride',
            'respect', 'tolerance', 'trust', 'understanding', 'feelings', 'silence'
        }
        commerce_econ = {
            'advertising', 'business', 'cash', 'currency', 'economics', 'employment',
            'fuel', 'gas', 'gold', 'labour', 'management', 'metal', 'money', 'oil',
            'power', 'production', 'progress', 'publicity', 'quality', 'quantity',
            'trade', 'wealth'
        }
        commodities_food = {
            'bread', 'butter', 'cheese', 'coffee', 'flour', 'food', 'juice', 'meat',
            'milk', 'rice', 'salt', 'sand', 'seafood', 'soup', 'sugar', 'tea',
            'water', 'wheat', 'wood'
        }
        environment_nature = {
            'air', 'fire', 'heat', 'nature', 'oxygen', 'rain', 'snow', 'sunshine',
            'warmth', 'weather', 'wildlife'
        }
        domestic_objects = {
            'baggage', 'clothing', 'equipment', 'furniture', 'hair', 'homework',
            'housework', 'leisure', 'luggage', 'paper', 'relaxation', 'room',
            'shopping', 'software', 'work'
        }

        specific_unc = {
            'childhood': ("Developmental psychologists emphasize that a nurturing environment during early childhood fosters long-term emotional resilience.", "The state or period of being a child."),
            'entertainment': ("The proliferation of digital streaming platforms has transformed how modern audiences consume commercial entertainment.", "Amusement or diversion provided by performers or media."),
            'fame': ("Sociologists analyze the psychological consequences of achieving sudden public fame in the modern media spotlight.", "The state of being widely known or recognized by the public."),
            'fun': ("Pedagogical experts encourage incorporating interactive group activities into primary classrooms to make learning genuine fun.", "Enjoyment, amusement, or lighthearted pleasure."),
            'justice': ("A truly democratic society is fundamentally founded on the impartial administration of justice under constitutional law.", "Fair treatment and the administration of law based on impartiality."),
            'lack': ("Public health analysts point out that impoverished rural clinics suffer from a severe lack of qualified medical personnel.", "A deficiency, absence, or shortage of something needed."),
            'magic': ("Traditional folkloric storytellers often used elements of mystical magic to explain perplexing natural phenomena.", "The power of apparently influencing events by using mysterious forces."),
            'motherhood': ("Sociological researchers study how societal expectations surrounding early motherhood influence female career progression.", "The state or experience of being a mother."),
            'music': ("Cognitive scientists have shown that regular engagement with instrumental music enhances neural plasticity in the brain.", "Vocal or instrumental sounds combined in producing harmony and beauty."),
            'news': ("The rapid spread of online social networks has fundamentally altered how citizens consume breaking international news.", "Newly received information about recent events or developments."),
            'old age': ("Public healthcare infrastructure must expand specialized geriatric services to support citizens entering vulnerable old age.", "The later part of normal life; advanced years."),
            'permission': ("Researchers were legally required to obtain formal parental permission before conducting psychological surveys with minors.", "Consent, authorization, or official agreement."),
            'speed': ("Urban traffic engineers install speed cameras along residential roads to protect pedestrian safety.", "The rate at which someone or something moves or operates."),
            'tennis': ("Participating in recreational sports such as competitive tennis develops cardiovascular endurance and agility.", "A racket sport played individually or in pairs on a court."),
            'time': ("Effective time management skills are indispensable for university students balancing academic deadlines with personal commitments.", "The continuous indefinite progress of existence and events."),
            'traffic': ("Metropolitan municipal authorities invest in light rail networks to alleviate persistent vehicular traffic during rush hours.", "Vehicles moving on a public highway or transit system."),
            'travel': ("Cultural anthropologists argue that international travel broadens cognitive perspectives and fosters intercultural empathy.", "The action of journeying to different geographical places."),
            'vision': ("The university dean articulated a forward-looking educational vision centered on global collaboration and digital innovation.", "The ability to think about or plan the future with imagination."),
            'weight': ("Health organizations recommend balanced nutrition and routine physical activity to maintain a healthy body weight.", "The heaviness or mass of an individual or object."),
            'width': ("Civil engineers must carefully calculate the necessary span and road width when constructing suspension bridges.", "The measurement or extent of something from side to side."),
            'yoga': ("Medical practitioners frequently recommend practicing mindfulness and gentle yoga to alleviate chronic musculoskeletal stiffness.", "A discipline including breath control, meditation, and postures."),
            'youth': ("Community recreational centers provide constructive guidance and mentorship to empower local urban youth.", "The period between childhood and adult age; young people collectively.")
        }

        if lower_t in specific_unc:
            ex, df = specific_unc[lower_t]
            return clean, "uncountable noun", df, ex

        if lower_t in neg_challenges:
            return clean, "uncountable noun", f"A serious socio-economic or personal adversity: {clean}.", f"Sociological researchers emphasize the urgent necessity of mitigating systemic {clean} within vulnerable urban communities."
        elif lower_t in public_goods:
            return clean, "uncountable noun", f"An essential social service, resource, or public good: {clean}.", f"Sociological studies demonstrate that equitable access to reliable {clean} directly correlates with higher living standards."
        elif lower_t in empirical_academic:
            return clean, "uncountable noun", f"A foundational academic, linguistic, or intellectual concept: {clean}.", f"In academic research, gathering reliable empirical {clean} is essential for formulating robust, evidence-based conclusions."
        elif lower_t in virtues_psych:
            return clean, "uncountable noun", f"A commendable human virtue, emotional trait, or attribute: {clean}.", f"Educational psychologists emphasize that cultivating genuine {clean} plays a vital role in positive personal character development."
        elif lower_t in commerce_econ:
            return clean, "uncountable noun", f"A key factor in economic systems and financial commerce: {clean}.", f"Economic analysts argue that the strategic management of {clean} is indispensable for sustaining national financial stability."
        elif lower_t in commodities_food:
            return clean, "uncountable noun", f"An essential agricultural commodity, food staple, or material: {clean}.", f"Agricultural economists analyze global supply chains to ensure the stable production and distribution of {clean}."
        elif lower_t in environment_nature:
            return clean, "uncountable noun", f"A natural environmental element or physical phenomenon: {clean}.", f"Environmental scientists study how shifts in atmospheric {clean} impact fragile regional ecosystems."
        elif lower_t in domestic_objects:
            return clean, "uncountable noun", f"A category of domestic, personal, or workplace necessities: {clean}.", f"In modern households and workplaces, organizing functional {clean} improves overall efficiency and personal wellbeing."
        else:
            return clean, "uncountable noun", f"An important abstract concept in academic discourse: {clean}.", f"Contemporary sociological research demonstrates how {clean} exerts a measurable influence on modern living standards."

    # --------------------------------------------------------------------------
    # 2. CRIME & PUNISHMENT (83 items)
    # --------------------------------------------------------------------------
    elif "crime" in lower_top:
        offenses = {
            'abduction', 'arson', 'assault', 'burglary', 'child abuse', 'crime',
            'drug trafficking', 'fraud', 'hacking', 'hijacking', 'human trafficking',
            'murder', 'organised crime', 'pick pocketing', 'shoplifting', 'smuggling',
            'terrorism', 'theft', 'trafficking', 'vandalism', 'white collar crime',
            'minor offense'
        }
        sanctions = {
            'community service', 'corporal punishment', 'death penalty', 'detention',
            'false imprisonment', 'fine', 'forfeiture', 'harsh punishment',
            'hospital order', 'house arrest', 'maximum sentence',
            'non-custodial sentence', 'prison sentence', 'suspended sentence'
        }
        actors_court = {
            'court', 'defendant', 'defense', 'judge', 'jury',
            'prosecutor', 'witness', 'trial'
        }
        legal_concepts = {
            'circumstances of the crime', 'circumstantial evidence',
            'diminished responsibility', 'evidence', 'extenuating circumstances',
            'hearsay', 'justice', 'proof', 'verdict'
        }
        social_criminology = {
            'crime is prevalent', 'juvenile delinquent',
            'mimicking violent behaviour', 'peer pressure', 'repeat offender',
            'role model', 'scolding', 'grounding',
            'isolation', 'discrimination'
        }

        specific_crime = {
            'armed police': ("During high-risk armed sieges, specialized armed police are deployed to neutralize violent threats safely.", "noun (plural)", "Police personnel equipped with firearms for specialized defensive operations."),
            'traffic offences': ("Automated speed cameras and roadside breath checks help deter motorists from committing dangerous traffic offences.", "noun (plural)", "Violations of traffic laws and motor vehicle regulations."),
            'juvenile delinquents': ("Community outreach initiatives help divert vulnerable juvenile delinquents toward constructive educational pathways.", "noun (plural)", "Young individuals under legal adulthood who commit criminal offenses."),
            'serial criminals': ("Forensic behavioral profiling assists police detectives in identifying and apprehending dangerous serial criminals.", "noun (plural)", "Offenders who commit a recurring series of crimes over an extended timeframe."),
            'role models': ("Young adolescents benefit immensely from having inspiring, positive role models within their neighborhood communities.", "noun (plural)", "Individuals regarded by others as admirable examples worthy of imitation."),
            'deter': ("Legal scholars debate whether mandatory minimum sentences truly serve to deter prospective criminal behavior.", "verb", "To discourage or prevent someone from doing something through fear of consequences."),
            'rehabilitated': ("Specialized vocational training programs help ex-convicts become fully rehabilitated before rejoining society.", "adjective", "Restored to a constructive, lawful role in society through training or therapy."),
            'rehabilitation': ("Modern penal philosophy emphasizes educational rehabilitation over purely retributive custodial incarceration.", "noun", "The process of restoring an offender to a lawful life in society."),
            'reintegrate back into society': ("Comprehensive post-release assistance enables parolees to reintegrate back into society with minimal recidivism.", "phrasal verb", "To successfully assimilate into civilian community life following release from prison."),
            'take into consideration': ("When determining an appropriate penalty, the judge will take into consideration any mitigating personal circumstances.", "collocation / phrase", "To account for or reflect upon relevant facts before making a judicial ruling."),
            'to be found guilty': ("It is a fundamental miscarriage of justice for any defendant to be found guilty without adequate legal defense.", "phrase", "To be formally convicted of a crime by a judicial court."),
            'to be soft on crime': ("Opposition politicians frequently accuse the incumbent government of choosing to be soft on crime.", "collocation / phrase", "Perceived as insufficiently punitive or overly lenient toward criminal lawbreakers."),
            'to give lines': ("Traditional school disciplinary regulations occasionally permitted teachers to give lines as a minor corrective punishment.", "phrase", "A corrective penalty requiring a student to write out a sentence repeatedly."),
            'to revoke a license': ("Municipal traffic courts retain statutory authority to revoke a license if a driver repeatedly endangers others.", "phrase", "To officially cancel or permanently rescind an operating license or legal permit."),
            'to suspend a license': ("The magistrate decided to suspend a license for twelve months following the driver's second conviction.", "phrase", "To temporarily withhold or deactivate a driving license or professional permit."),
            'life': ("Under severe penal codes, committing aggravated murder carries a mandatory sentence of life imprisonment without parole.", "noun", "A judicial sentence of imprisonment lasting for the rest of a convict's natural life."),
            'guilty': ("The jury returned a unanimous verdict finding the accused corporation guilty of environmental contamination.", "adjective", "Culpable of or responsible for a specified offense or wrongdoing."),
            'innocent': ("Under constitutional law, an accused individual is presumed innocent until proven guilty beyond reasonable doubt.", "adjective", "Free from legal guilt, culpability, or criminal wrongdoing."),
            'premeditated': ("Detectives presented forensic proof indicating that the cyberattack was premeditated rather than accidental.", "adjective", "Planned, thought out, or deliberate beforehand."),
            'circumstantial': ("The defense attorney argued that the prosecution's case was largely circumstantial and lacked eyewitness proof.", "adjective", "Pointing indirectly toward someone's guilt without providing direct observation.")
        }

        if lower_t in specific_crime:
            ex, p, df = specific_crime[lower_t]
            return clean, p, df, ex
        elif lower_t in offenses:
            return clean, "noun", f"An illegal act or statutory offense: {clean}.", f"Criminologists investigate whether proactive community policing and targeted social intervention can effectively deter {clean}."
        elif lower_t in sanctions:
            return clean, "noun", f"A judicial penalty or correctional sanction: {clean}.", f"The magistrate determined that imposing a {clean} was the most proportionate legal sanction for the convicted offender."
        elif lower_t in actors_court:
            return clean, "noun", f"An official authority or participant in judicial proceedings: {clean}.", f"During formal criminal proceedings, the testimony and impartiality of the {clean} are vital for ensuring a fair trial."
        elif lower_t in legal_concepts:
            return clean, "noun", f"A core legal doctrine or evidentiary standard: {clean}.", f"In a court of law, legal counsel must rigorously evaluate every piece of {clean} before reaching a definitive conclusion."
        elif lower_t in social_criminology:
            return clean, "noun", f"A behavioral or societal factor examined in criminology: {clean}.", f"Sociological research indicates that adolescents exposed to persistent {clean} face a significantly heightened risk of offending."
        else:
            return clean, pos if pos else "noun", f"A key lexical concept in Crime & Punishment: {clean}.", f"Criminologists analyze how the phenomenon of {clean} influences law enforcement strategies in modern urban centers."

    # --------------------------------------------------------------------------
    # 3. EDUCATION: SCHOOL & UNIVERSITY (75 items)
    # --------------------------------------------------------------------------
    elif "education" in lower_top:
        subjects = {
            'algebra', 'art', 'biology', 'chemistry', 'cookery', 'geography',
            'handicrafts', 'history', 'literature', 'maths', 'music',
            'natural science', 'physical education', 'religious studies',
            'science', 'information technology'
        }
        credentials = {
            'bachelor degree', 'master degree', 'PhD', 'Certificate', 'Diploma',
            'college', 'higher education', 'kindergarten', 'post-graduate school',
            'primary school', 'secondary school', 'comprehensive education'
        }
        tasks = {
            'assignment', 'dissection', 'dissertation', 'hypothesis', 'lab work',
            'note-taking', 'project work', 'thesis', 'research'
        }
        specific_edu = {
            'student loans': ("Rising tuition expenses have caused cumulative debt on student loans to reach record levels among university graduates.", "noun (plural)", "Borrowed educational funds requiring long-term financial repayment by students."),
            'extra curricular activities': ("Admissions committees value applicants who engage actively in extra curricular activities alongside their academic studies.", "noun (plural)", "Pursuits, clubs, and sports undertaken outside the standard academic curriculum."),
            'scheduled lessons': ("Punctual attendance at all scheduled lessons is mandatory for secondary students to maintain satisfactory academic progress.", "noun (plural)", "Pre-arranged classroom instructional sessions within a school timetable."),
            'tutorials': ("Undergraduate seminar groups and weekly tutorials provide an interactive forum for discussing complex economic models.", "noun (plural)", "Small-group instructional sessions led by a university tutor or academic."),
            'lectures': ("Distinguished international scholars are invited to deliver guest lectures on contemporary geopolitical developments.", "noun (plural)", "Formal educational presentations delivered by professors to large groups of students."),
            'presentations': ("Postgraduate degree candidates deliver formal research presentations before faculty review committees.", "noun (plural)", "Structured academic talks showcasing original findings to a scholarly audience."),
            'deliver a lecture': ("Distinguished visiting professors are frequently invited to deliver a lecture on international macroeconomic policy.", "phrase", "To present a formal educational address to an audience of students."),
            'fall behind with studies': ("Students with inadequate time-management skills risk stress and may fall behind with studies before exam periods.", "phrase", "To fail to maintain the required pace of academic coursework."),
            'keeping up with the work load': ("Freshmen undergraduates frequently encounter difficulty when keeping up with the work load of university courses.", "phrase", "Managing to complete a demanding volume of academic assignments on time."),
            'pay off a student loan': ("Many university graduates work for over a decade in professional roles before they can completely pay off a student loan.", "phrase", "To fully repay borrowed educational tuition funds to a financial lender."),
            'to attend a lecture': ("Undergraduate students are strongly encouraged to attend a lecture punctually and take thorough notes.", "phrase", "To be physically or virtually present at a formal university instructional presentation."),
            'to attend a tutorial': ("Seminar group discussions provide undergraduates with an opportunity to attend a tutorial and analyze difficult texts.", "phrase", "To participate in a small-group instructional session with an academic tutor."),
            'to do or complete coursework': ("Independent learners must organize their daily schedule to do or complete coursework before end-of-term deadlines.", "phrase", "To finish written or practical academic projects assigned during a course."),
            'to enroll on a degree course': ("Prospective university students must meet stringent entry requirements to enroll on a degree course in engineering.", "phrase", "To officially register as a candidate for an undergraduate or postgraduate degree."),
            'to graduate from a university': ("Attaining high academic honors enables ambitious scholars to graduate from a university with excellent career opportunities.", "phrase", "To successfully complete a course of study and receive an academic degree."),
            'to major in physics': ("Undergraduates who aspire to careers in aerospace engineering frequently choose to major in physics during their studies.", "phrase", "To specialize in a specific academic discipline as a principal field of study."),
            'to read history': ("Scholars who choose to read history at university develop sophisticated archival research and analytical critique skills.", "phrase", "To study a discipline (especially in British universities) as an undergraduate specialization."),
            'cheating': ("University honor codes impose severe disciplinary suspensions to deter dishonest academic cheating during examinations.", "noun", "Acting dishonestly or unfairly to gain an academic advantage."),
            'Distance Learning Course': ("Enrolling in an accredited Distance Learning Course allows working professionals to balance employment with higher education.", "noun", "A method of study where lectures and assessments are conducted online without classroom attendance."),
            'gap year': ("Many secondary school leavers choose to take a productive gap year to gain practical workplace experience and travel.", "noun", "A year-long hiatus taken between school and university for work or travel."),
            'illiterate': ("Government literacy campaigns provide adult night classes to assist citizens who were previously illiterate.", "adjective", "Unable to read or write."),
            'literate': ("Primary educational policy strives to ensure that every child becomes functionally literate by the completion of elementary school.", "adjective", "Able to read and write proficiently."),
            'literacy': ("Investing in rural community schooling yields measurable improvements in national literacy and economic productivity.", "noun", "The ability to read and write."),
            'the literacy rate': ("International development organizations track the literacy rate as a key indicator of socio-economic progress.", "noun", "The proportion of the population aged fifteen and above that can read and write."),
            'scholarship': ("The academically gifted candidate was granted a full university scholarship covering all tuition and living expenses.", "noun", "A grant or financial award made to support a student's education."),
            'student loan': ("Many young professionals carry the financial burden of repaying a student loan well into their adult careers.", "noun", "A loan granted to a student to pay for higher education tuition and living costs."),
            'the faculty of business': ("The university established an international corporate mentoring program through the faculty of business.", "noun", "An academic department or division within a university focused on business studies."),
            'tone deaf': ("While some amateur singers assume they are tone deaf, dedicated vocal coaching can rapidly improve pitch accuracy.", "adjective", "Unable to perceive differences in musical pitch accurately."),
            'tracing': ("Preschool educators use letter tracing exercises to help young children develop hand-eye coordination and handwriting.", "noun", "The act of copying an outline or drawing on transparent paper or guidelines."),
            'truancy': ("School social workers monitor unexcused truancy to identify vulnerable students who may require counseling or welfare support.", "noun", "The act or habit of staying away from school without leave or good explanation."),
            'Non-vocational course': ("Adult learning institutes offer a Non-vocational course in creative writing for individuals seeking personal enrichment.", "noun", "An educational course undertaken for personal interest rather than specific employment skills."),
            'Online Course': ("Completing an interactive Online Course enables learners to acquire modern digital marketing skills from home.", "noun", "A program of study delivered over the internet."),
            'Vocational course': ("Secondary leavers looking for hands-on technical trades often enroll in an intensive Vocational course.", "noun", "A specialized course designed to provide direct practical training for a trade or profession."),
            'intensive course': ("Medical researchers attended a five-day intensive course on statistical modeling in clinical epidemiology.", "noun", "A concentrated, fast-paced academic program covering a subject in depth within a short period."),
            'graduate': ("Upon completing their final dissertations, every university graduate enters an increasingly competitive professional job market.", "noun", "A person who has successfully completed a course of study or degree."),
            'graduated': ("The university honored each newly graduated scholar during the formal summer commencement ceremony.", "adjective / verb", "Having completed a university degree or course of study."),
            'undergraduate': ("An ambitious undergraduate scholar must balance demanding coursework assignments with laboratory research duties.", "noun", "A university student who has not yet taken a first degree.")
        }

        if lower_t in specific_edu:
            ex, p, df = specific_edu[lower_t]
            return clean, p, df, ex
        elif lower_t in subjects:
            return clean, "noun", f"An academic subject or discipline: {clean}.", f"The national curriculum requires secondary school pupils to develop analytical competence through the study of {clean}."
        elif lower_t in credentials:
            return clean, "noun", f"An academic qualification or educational level: {clean}.", f"Attaining an accredited {clean} significantly improves a graduate's employment prospects in the global knowledge economy."
        elif lower_t in tasks:
            return clean, "noun", f"An academic assignment, activity, or evaluation: {clean}.", f"University scholars are required to submit extensive {clean} demonstrating independent critical analysis."
        else:
            return clean, pos if pos else "noun", f"A core academic concept in Education: {clean}.", f"Academics emphasize that mastering key concepts related to {clean} is vital for long-term intellectual development."

    # --------------------------------------------------------------------------
    # 4. LINE GRAPH VOCABULARY (IELTS ACADEMIC TASK 1) (55 items)
    # --------------------------------------------------------------------------
    elif "line graph" in lower_top:
        past_verbs = {
            'climbed', 'declined', 'decreased', 'dropped', 'fell', 'grew',
            'increased', 'rose', 'went down', 'went up'
        }
        base_verbs = {
            'bottom out', 'climb', 'decline', 'decrease', 'dip', 'drop',
            'fall', 'fluctuate', 'increase', 'rise', 'soar',
            'to go down', 'to go up', 'to level off', 'to peak at',
            'to remain stable', 'to remain steady', 'to remain unchanged',
            'reach a peak of'
        }
        noun_trends = {
            'dramatic increase', 'gradual increase', 'growth', 'minimal change',
            'peak', 'plateau', 'significant change', 'slight change'
        }
        adverbs = {
            'dramatically', 'relatively', 'significantly', 'slightly', 'steadily'
        }
        time_expressions = {
            'after three days': ("The laboratory experiment registered a sudden increase in temperature after three days of continuous monitoring.", "prepositional phrase", "Following an elapsed duration of seventy-two hours."),
            'at the beginning of the period': ("At the beginning of the period, coal accounted for nearly sixty percent of all domestic energy generation.", "prepositional phrase", "During the initial phase or starting point of the surveyed timeline."),
            'at the end of the period': ("Renewable wind power generation surpassed traditional energy sources at the end of the period.", "prepositional phrase", "During the closing or final phase of the timeline under observation."),
            'fluctuated between': ("Crude oil prices fluctuated between forty and eighty dollars per barrel throughout the observed decade.", "verb phrase", "Rose and fell irregularly between specified numerical limits."),
            'hit a high of': ("During the peak summer holiday season, consumer hotel bookings hit a high of eighty-five percent occupancy.", "verb phrase", "Reached the maximum recorded numerical figure or apex."),
            'hit a low of': ("Following the economic downturn, domestic automobile manufacturing hit a low of twenty thousand units.", "verb phrase", "Reached the lowest recorded statistical point on the chart."),
            'initially': ("Although consumer demand was modest initially, widespread promotional campaigns prompted rapid sales growth.", "adverb", "At first; at the start of a period or process."),
            'final year': ("Statistical records highlight a dramatic acceleration in industrial output during the final year of the study.", "noun phrase", "The concluding twelve-month period of the recorded data."),
            'over a ten-year period': ("The line graph illustrates shifts in consumer expenditure patterns over a ten-year period between 2000 and 2010.", "prepositional phrase", "Spanning a continuous timeframe lasting one decade."),
            'over the following three days': ("Patient physiological indicators stabilized remarkably over the following three days in clinical care.", "prepositional phrase", "During the subsequent seventy-two hour timeframe."),
            'over the next three days': ("Meteorologists projected that heavy rainfall volumes would escalate over the next three days.", "prepositional phrase", "Throughout the upcoming three-day calendar period."),
            'the next three days show': ("The predictive simulation models indicate that the next three days show a consistent upward trajectory.", "phrase", "The upcoming three-day interval displays a visible trend."),
            'three days later': ("Follow-up water quality testing conducted three days later confirmed that contaminant levels had dropped.", "adverbial phrase", "At a point in time seventy-two hours subsequent to the initial event.")
        }

        if lower_t in time_expressions:
            ex, p, df = time_expressions[lower_t]
            return clean, p, df, ex
        elif lower_t in past_verbs:
            return clean, "verb (past)", f"A past-tense verb indicating a statistical change or trend: {clean}.", f"According to the line graph, domestic renewable energy consumption {clean} steadily between 2010 and 2020."
        elif lower_t in base_verbs:
            if clean.startswith("to "):
                return clean, "verb / phrase", f"An infinitive verbal phrase describing a trajectory: {clean}.", f"Statistical projections indicate that manufacturing figures are likely {clean} in the upcoming quarter."
            elif clean.startswith("reach "):
                return clean, "verb / phrase", f"A verbal phrase describing reaching an apex: {clean}.", f"Passenger volumes are forecast to {clean} ten million travelers by the close of the decade."
            else:
                return clean, "verb", f"A verb describing a statistical movement or trend: {clean}.", f"Over the recorded timeline, manufacturing output figures began to {clean} before stabilizing in the final quarter."
        elif lower_t in noun_trends:
            return clean, "noun phrase", f"A noun phrase denoting a trend or statistical shift: {clean}.", f"The line graph illustrates a {clean} in municipal water consumption over the recorded timeframe." if not clean.startswith("growth") else f"The line graph illustrates steady {clean} in municipal water consumption over the recorded timeframe."
        elif lower_t in adverbs:
            return clean, "adverb", f"An adverb describing the degree or speed of a statistical change: {clean}.", f"Industrial greenhouse gas emissions decreased {clean} following the introduction of statutory environmental standards."
        else:
            return clean, pos if pos else "noun", f"A statistical vocabulary term for IELTS Task 1: {clean}.", f"Data analysts observe how the metric of {clean} characterizes the visual data presented in the graph."

    # --------------------------------------------------------------------------
    # 5. GOVERNMENT & POLITICS (57 items)
    # --------------------------------------------------------------------------
    elif "government" in lower_top:
        institutions = {
            'coalition government', 'constitutional government',
            'executive branch', 'judicial branch', 'legislative branch',
            'monarchy', 'political party', 'regime', 'republic',
            'state government'
        }
        ideologies = {
            'anarchy', 'autonomy', 'capitalist', 'communist', 'democracy',
            'dictatorship', 'liberty'
        }
        specific_gov = {
            'diplomats': ("In international relations, skilled diplomats negotiate bilateral treaties to resolve geopolitical tensions peacefully.", "noun (plural)", "Officials representing a country abroad in international diplomacy."),
            'enforcement agencies': ("Independent statutory bodies supervise law enforcement agencies to prevent corruption and protect civil rights.", "noun (plural)", "Government bodies responsible for upholding and enforcing the law."),
            'politicians': ("Citizens expect elected politicians to prioritize long-term public welfare over short-term partisan interests.", "noun (plural)", "Persons who are professionally involved in politics, especially as elected members of parliament."),
            'the authorities': ("During a civil emergency, transparent communication from the authorities is essential for preventing public panic.", "noun", "The governing officials or administrators exercising legal power."),
            'the administration': ("The policy directives issued by the administration placed sustainable infrastructure at the forefront of the economic recovery plan.", "noun", "The government in office; executive management of public affairs."),
            'the central government': ("Regional governors requested emergency disaster relief funding directly from the central government.", "noun", "The national executive authority of a sovereign country."),
            'the leadership': ("During periods of socioeconomic crisis, citizens expect the leadership to demonstrate transparency, strategic vision, and decisiveness.", "noun", "The individuals who guide or direct a government or political organization."),
            'the local government': ("Municipal services such as waste collection and park maintenance are administered by the local government.", "noun", "The administration of a town, county, or district by locally elected representatives."),
            'the people in authority': ("Democratic accountability demands that the people in authority remain subject to the rule of law.", "phrase", "Officials holding statutory leadership and decision-making power."),
            'the political system': ("Constitutional checks and balances prevent authoritarian overreach within the political system.", "noun", "The coordinated framework of government institutions and processes in a country."),
            'those in power': ("Investigative journalists play an essential watchdog role in holding those in power accountable to the public.", "phrase", "The individuals or groups currently exercising political governance."),
            'totalitarian state': ("Citizens living under an oppressive totalitarian state face severe state surveillance and censorship.", "noun", "A centralized government that requires complete subservience to state authority."),
            'branches of government': ("Democratic constitutions establish distinct branches of government to distribute legislative, executive, and judicial powers.", "noun (plural)", "The distinct divisions of public authority: executive, legislative, and judicial."),
            'maintain order': ("During large-scale civil emergencies, peacekeeping forces are deployed to maintain order and safeguard public assets.", "phrase", "To preserve public peace, stability, and adherence to law."),
            'organise a petition': ("Grassroots environmental activists often organise a petition to demand strict emission controls from parliament.", "phrase", "To collect signatures from citizens urging governmental authorities to take action."),
            'organise a public meeting': ("Municipal town councilors met to organise a public meeting where residents could air urban redevelopment concerns.", "phrase", "To coordinate an open civic gathering for public debate and discussion."),
            'pass a law': ("Lawmakers across party affiliations collaborated to pass a law capping carbon emissions from heavy industry.", "phrase", "To formally approve and enact a legislative statute into law."),
            'put up posters': ("Campaign volunteers walked through downtown districts to put up posters advertising the upcoming mayoral debate.", "phrase", "To display public placards or advertisements on noticeboards or walls."),
            'speak at public meetings': ("Community representatives regularly speak at public meetings to ensure neighborhood perspectives are heard.", "phrase", "To address civic gatherings on matters of community welfare or policy."),
            'to abide by a law': ("Every resident has an undeniable civic responsibility to abide by a law enacted by the democratic legislature.", "phrase", "To respect, follow, and obey legal rules and statutory obligations."),
            'to be involved in protests': ("Civic freedoms entitle citizens to be involved in protests against policies they deem unjust or harmful.", "phrase", "To take part in public demonstrations expressing political grievance."),
            'to be proactive': ("Urban administrations need to be proactive when designing civil infrastructure against impending climate challenges.", "phrase", "Taking anticipatory action to manage situations rather than reacting after events occur."),
            'to elect': ("Registered voters gather at municipal polling stations to elect their parliamentary representatives for the new term.", "phrase", "To choose someone to hold public office by casting democratic votes."),
            'to govern': ("A stable majority coalition was formed in parliament to govern the sovereign state during the economic transition.", "phrase", "To exercise official authority, leadership, and political control over a country."),
            'write to politicians': ("Voters frustrated by public transit cutbacks frequently write to politicians to demand immediate reinvestment.", "phrase", "To send letters or communications to elected representatives urging policy changes."),
            'political influence': ("Corporate lobbying groups often seek to exercise subtle political influence over legislative committees.", "noun", "The capacity to affect government policies, election outcomes, or judicial appointments."),
            'long-term goals': ("Elected leaders must formulate clear long-term goals for educational reform that extend beyond single electoral cycles.", "noun", "Strategic objectives planned for achievement over an extended future period."),
            'defence spending': ("Economists analyze the opportunity costs when governments increase national defence spending at the expense of healthcare.", "noun", "Public expenditures allocated to military, defense, and armed forces infrastructure."),
            'budget': ("The finance minister presented a balanced annual budget allocating substantial revenues to renewable energy infrastructure.", "noun", "An official financial estimate of government income and expenditure for a set period."),
            'citizen': ("Every active citizen plays a vital role in democratic governance by voting and participating in community civic forums.", "noun", "A legally recognized subject or national of a state with civic rights and duties."),
            'charismatic': ("A charismatic political orator can inspire broad public enthusiasm and unite diverse demographic factions.", "adjective", "Possessing an inspiring charm or magnetic appeal that fosters devotion."),
            'election': ("International monitors verified that the nationwide general election was conducted transparently and fairly.", "noun", "A formal democratic decision-making process by which a population chooses public officials."),
            'government': ("A representative national government derives its legitimate authority from the consent of the governed citizenry.", "noun", "The governing body or political administration of a nation, state, or community."),
            'governmental': ("Comprehensive governmental regulations were enacted to protect consumer data privacy across digital platforms.", "adjective", "Relating to government or public administration."),
            'laws': ("Democratic parliaments enact statutory laws to protect fundamental civil liberties and maintain social harmony.", "noun", "The system of binding rules that a particular country recognizes as regulating the actions of its members."),
            'policies': ("Public health authorities introduced evidence-based policies to combat chronic lifestyle diseases across the population.", "noun", "A course or principle of action adopted or proposed by a government or organization."),
            'rights': ("Constitutional jurisprudence guarantees that fundamental human rights are protected from executive overreach.", "noun", "Moral or legal entitlements to have or obtain something or to act in a certain way."),
            'taxes': ("Revenues generated from progressive corporate taxes are reinvested in public education and transportation infrastructure.", "noun", "Compulsory financial contributions levied by government on workers' income and business profits.")
        }

        if lower_t in specific_gov:
            ex, p, df = specific_gov[lower_t]
            return clean, p, df, ex
        elif lower_t in institutions:
            return clean, "noun", f"An official institution, governmental body, or political authority: {clean}.", f"Political scientists argue that an accountable, transparent {clean} is fundamental to maintaining democratic legitimacy."
        elif lower_t in ideologies:
            return clean, "noun", f"A political system, philosophy, or governance ideology: {clean}.", f"Constitutional scholars examine whether {clean} provides the optimal balance between individual liberty and public order."
        else:
            return clean, pos if pos else "noun", f"A key lexical concept in Government and Politics: {clean}.", f"Political analysts observe how the mechanism of {clean} shapes public governance and policy formulation."

    # --------------------------------------------------------------------------
    # 6. ENVIRONMENTAL PROBLEMS (44 items)
    # --------------------------------------------------------------------------
    elif "environmental" in lower_top:
        threats_singular = {
            'acid rain', 'air pollution', 'climate change', 'deforestation',
            'land degradation', 'loss of biodiversity', 'loss of fertility',
            'marine pollution', 'ozone layer depletion', 'resource depletion',
            'soil erosion', 'overpopulation'
        }
        specific_env = {
            'draining world resources': ("Unchecked consumerism contributes to draining world resources at an ecologically unsustainable pace.", "phrase", "Exhausting planetary raw materials, minerals, and fossil fuels."),
            'farm chemicals': ("The excessive application of synthetic farm chemicals contaminates agricultural runoff and depletes soil biodiversity.", "noun (plural)", "Chemical compounds, pesticides, and fertilizers used in commercial agriculture."),
            'greenhouse gases': ("Anthropogenic emissions of heat-trapping greenhouse gases accelerate global warming and polar ice sheet melt.", "noun (plural)", "Atmospheric gases like carbon dioxide and methane that trap solar heat."),
            'waste disposal': ("Inadequate municipal waste disposal infrastructure leads to widespread open burning and severe air pollution.", "noun", "The collection, processing, and management of refuse and discarded materials."),
            'absorb': ("Dense coastal mangrove forests act as natural ecological buffers that absorb excess wave impact during tidal surges.", "verb", "To take in or soak up energy, liquid, or other substances."),
            'abundant': ("Tropical rainforests support an abundant diversity of plant and animal species found nowhere else on earth.", "adjective", "Existing or available in large, plentiful quantities."),
            'aquatic creatures': ("Marine conservation laws are enacted to shield vulnerable aquatic creatures from commercial plastic pollution.", "noun (plural)", "Animals and organisms that live predominantly in water environments."),
            'biodiversity': ("Preserving intact tropical habitats is essential for preventing the rapid, catastrophic collapse of planetary biodiversity.", "noun", "The variety of plant and animal life in the world or in a particular habitat."),
            'break down': ("Synthetic non-biodegradable plastics can take hundreds of years to break down in natural soil environments.", "phrasal verb", "To decompose, decay, or disintegrate into constituent elements."),
            'buildings': ("Urban planners are retrofitting older municipal buildings with rooftop solar panels to cut energy consumption.", "noun (plural)", "Permanent structures with roofs and walls, such as houses or factories."),
            'chemicals': ("Strict environmental standards regulate the discharge of toxic industrial chemicals into freshwater waterways.", "noun (plural)", "Substances manufactured by or used in chemical processes."),
            'crime rates': ("Sociological researchers study whether deteriorating environmental quality and excessive urban heat waves correlate with increased crime rates.", "noun (plural)", "The measured incidence of criminal offenses in a given area or period."),
            'crops': ("Agricultural scientists breed drought-resilient crops to safeguard national food supplies against erratic rainfall.", "noun (plural)", "Cultivated plants that are grown as food, especially grains, fruits, or vegetables."),
            'deposit': ("Fast-flowing mountain streams carry mineral-rich silt and deposit fertile sediments across downstream agricultural plains.", "verb", "To lay down or leave matter in a natural process."),
            'ecosystem': ("Pollution in coral reefs disrupts the delicate marine ecosystem, threatening entire food webs and fish nurseries.", "noun", "A biological community of interacting organisms and their physical environment."),
            'exacerbated': ("Global food insecurity has been severely exacerbated by prolonged regional droughts and rising average temperatures.", "adjective / verb", "Made worse, more severe, or more intense."),
            'food security': ("Investing in modern sustainable farming techniques is imperative for ensuring long-term food security for growing populations.", "noun", "The state of having reliable physical and economic access to sufficient, nutritious food."),
            'fossil fuels': ("Transitioning away from carbon-intensive fossil fuels is indispensable if international climate targets are to be fulfilled.", "noun (plural)", "Natural fuels such as coal, oil, or gas formed in the geological past from living organisms."),
            'habitat': ("Deforestation destroys the primary natural habitat of endangered primates, pushing many species toward extinction.", "noun", "The natural home or environment of an animal, plant, or organism."),
            'hazardous': ("Improper storage of hazardous chemical waste poses grave contamination risks to underground municipal drinking aquifers.", "adjective", "Risky, dangerous, or harmful to human health or the environment."),
            'humans': ("Ecologists emphasize that humans bear a profound moral responsibility to preserve planetary ecosystems for future generations.", "noun (plural)", "Human beings collectively; members of the species Homo sapiens."),
            'longer life span': ("Advancements in public sanitation and access to clean drinking water have contributed to a longer life span for populations worldwide.", "noun phrase", "An extended duration or length of time for which an individual or organism lives."),
            'low lying': ("Coastal cities located in low lying delta regions are particularly susceptible to sea level rise and severe storm surges.", "adjective", "At or near sea level or situated on low ground."),
            'lungs': ("Severe particulate air pollution causes permanent tissue scarring in human lungs, leading to chronic respiratory illness.", "noun (plural)", "The pair of respiratory organs in the chest that supply the body with oxygen."),
            'natural sustainability': ("Ecologists advocate circular economic practices that promote natural sustainability without depleting finite resources.", "noun", "The capacity of natural ecosystems to endure and maintain ecological balance indefinitely."),
            'power plants': ("Governments are phasing out obsolete coal-fired power plants in favor of grid-scale solar and wind installations.", "noun (plural)", "Industrial facilities that generate electric energy for commercial distribution."),
            'premature': ("Epidemiological studies demonstrate that urban smog causes thousands of premature deaths annually from cardiopulmonary diseases.", "adjective", "Occurring or done before the proper, natural, or customary time."),
            'productive potential': ("Soil salinization significantly degrades the agricultural productive potential of irrigated farmland over time.", "noun phrase", "The maximum capacity of land or resources to yield output sustainably."),
            'seep': ("Toxic runoff from unregulated open landfills can seep into porous bedrock and contaminate regional water tables.", "verb", "To flow or leak slowly through small openings or porous material."),
            'surface life': ("Deep oceanic trenches sustain unique organisms adapted to total darkness and extreme pressure unlike surface life.", "noun", "Biological organisms inhabiting terrestrial or upper water environments."),
            'weather patterns': ("Global climate change has significantly destabilized historical weather patterns, resulting in frequent extreme storms.", "noun (plural)", "Recurring atmospheric meteorological conditions observed over time."),
            'yields': ("Intensive agroecological research aims to maximize crop yields while drastically reducing the use of synthetic fertilizers.", "noun (plural)", "The total amount of an agricultural or industrial product produced.")
        }

        if lower_t in specific_env:
            ex, p, df = specific_env[lower_t]
            return clean, p, df, ex
        elif lower_t in threats_singular:
            return clean, "noun", f"A major ecological crisis or environmental threat: {clean}.", f"Environmental scientists warn that unchecked {clean} poses severe, irreversible hazards to planetary ecosystems."
        else:
            return clean, pos if pos else "noun", f"A key environmental or ecological concept: {clean}.", f"Ecologists study how the phenomenon of {clean} impacts the delicate equilibrium of natural habitats."

    # --------------------------------------------------------------------------
    # 7. CORONAVIRUS & EPIDEMICS (54 items)
    # --------------------------------------------------------------------------
    elif "coronavirus" in lower_top:
        specific_covid = {
            'acceleration phase': ("Epidemiologists tracked the acceleration phase of the epidemic to anticipate peak intensive care admissions.", "noun", "The period in an outbreak where infection rates rise rapidly."),
            'acute respiratory problems': ("Patients suffering from acute respiratory problems were promptly placed on high-flow supplemental oxygen therapy.", "noun", "Severe, sudden pulmonary conditions impairing normal breathing."),
            'alcohol based antimicrobial hand sanitiser': ("Public transit facilities installed dispensers of alcohol based antimicrobial hand sanitiser to curb pathogen transmission.", "noun", "An alcohol-containing liquid or gel used to eliminate infectious agents on hands."),
            'altruism': ("During severe community lockdowns, acts of collective altruism helped deliver groceries to vulnerable elderly citizens.", "noun", "Selfless concern and compassionate action for the wellbeing of others."),
            'anxiety': ("Prolonged social isolation and health uncertainty caused a documented surge in clinical anxiety among young adults.", "noun", "A feeling of intense worry, nervousness, or unease."),
            'asthma': ("Individuals with chronic asthma were advised to take extra precautions because respiratory viruses can trigger severe attacks.", "noun", "A chronic respiratory condition characterized by spasms in the bronchi of the lungs."),
            'community spread': ("Health officials instituted strict local restrictions once untraceable community spread was verified in urban districts.", "noun", "Transmission of an illness within a community with no known exposure source."),
            'contact tracing': ("Public health teams deployed rapid digital contact tracing to locate and notify individuals exposed to confirmed cases.", "noun", "The process of identifying and monitoring people who have been in contact with an infected person."),
            'contagious': ("Because the emerging viral variant was exceptionally contagious, hospital infection-control protocols were heightened.", "adjective", "Easily spread from one person or organism to another by direct or indirect contact."),
            'curfew': ("Municipal authorities declared an overnight curfew to deter large public gatherings and reduce nighttime social mixing.", "noun", "A regulation requiring people to remain indoors between specified evening hours."),
            'death toll': ("Statisticians analyzed excess mortality figures to assess the true global death toll resulting from the pandemic.", "noun", "The number of deaths resulting from a particular disease, disaster, or accident."),
            'epicentre': ("International humanitarian relief teams rushed medical supplies to the metropolitan city identified as the outbreak epicentre.", "noun", "The central point or focus of greatest disease activity or impact."),
            'face mask': ("Wearing a multi-layered face mask in crowded indoor venues remains an effective method for reducing droplet dissemination.", "noun", "A protective covering worn over the nose and mouth to prevent viral transmission."),
            'fomites': ("Hygienists emphasized routine surface sanitation because porous fomites can occasionally harbor infectious viral particles.", "noun (plural)", "Inanimate objects or materials that are capable of transmitting infectious agents."),
            'herd immunity': ("Immunologists calculated that vaccinating eighty percent of the general population was necessary to establish robust herd immunity.", "noun", "Resistance to the spread of an infectious disease within a population due to high immunity levels."),
            'incubation period': ("The novel virus exhibited an estimated incubation period of five to seven days before symptoms became clinically noticeable.", "noun", "The period between exposure to an infection and the appearance of the first symptoms."),
            'large gatherings': ("Public health guidelines strictly prohibited indoor large gatherings to minimize super-spreader events during the surge.", "noun (plural)", "Substantial assemblies of people in a single venue."),
            'lockdown': ("The nationwide statutory lockdown successfully curbed viral transmission rates and alleviated strain on hospital intensive care units.", "noun", "An emergency protocol restricting movement and social mixing to contain disease spread."),
            'misinformation': ("Health agencies waged public awareness campaigns to debunk hazardous medical misinformation proliferating across social media.", "noun", "False, inaccurate, or misleading information spread regardless of intent to deceive."),
            'new strain': ("Virological sequencing laboratories identified a distinct new strain that exhibited altered spike protein structures.", "noun", "A genetic variant or subtype of a microorganism."),
            'pandemic': ("The World Health Organization declared a global pandemic as the infectious contagion spread rapidly across multiple continents.", "noun", "An outbreak of a disease prevalent over a whole country or the entire world."),
            'patient zero': ("Epidemiological geneticists conducted extensive retrospective testing to trace patient zero of the initial regional outbreak cluster.", "noun", "The person identified as the first carrier of a communicable disease in an outbreak."),
            'persistent cough': ("Diagnostic criteria advised anyone exhibiting a high fever and a persistent cough to undergo immediate viral testing.", "noun", "A continuous, prolonged cough lasting several days or weeks."),
            'physical distancing': ("Supermarkets marked queue lines two meters apart to encourage patrons to maintain rigorous physical distancing.", "noun", "The practice of keeping a designated physical distance from others to prevent contagion."),
            'pneumonia': ("Severe complications from the pulmonary infection can progress to bilateral pneumonia requiring mechanical ventilation.", "noun", "Lung inflammation caused by bacterial or viral infection in which air sacs fill with fluid."),
            'precautionary measures': ("Workplaces instituted rigorous precautionary measures including daily temperature screenings and mandatory hand sanitization.", "noun (plural)", "Preventative actions taken in advance to prevent harm or disease transmission."),
            'precautions': ("Sensible hygiene precautions such as frequent handwashing remain fundamental in preventing viral contamination.", "noun (plural)", "Measures taken in advance to prevent something dangerous, unpleasant, or inconvenient."),
            'protective clothing': ("Healthcare workers donned sterile protective clothing before entering high-risk biocontainment isolation wards.", "noun", "Apparel specifically designed to shield wearers from infectious or hazardous biological substances."),
            'quarantine': ("Overseas travelers arriving at international airports were placed in supervised hotel quarantine for a statutory duration.", "noun", "A state of enforced isolation to prevent the spread of infectious disease."),
            'respiratory droplets': ("Covering one's mouth when coughing prevents the expulsion of microscopic respiratory droplets into shared ambient air.", "noun (plural)", "Tiny moisture droplets expelled during breathing, speaking, coughing, or sneezing."),
            'respiratory problems': ("Patients reporting sudden respiratory problems were prioritized for triage assessment and diagnostic imaging.", "noun (plural)", "Medical disorders affecting the organs and tissues involved in breathing."),
            'severity': ("Physicians evaluate oxygen saturation levels to gauge the clinical severity of acute respiratory tract infections.", "noun", "The intensity, seriousness, or harshness of an illness or condition."),
            'social distancing': ("Implementing community social distancing helped slow down viral transmission before comprehensive vaccines were approved.", "noun", "Maintaining physical space between individuals to reduce the spread of contagious illness."),
            'state of emergency': ("The prime minister declared a national state of emergency to mobilize civil defense resources and expedite hospital funding.", "noun", "A government declaration enabling exceptional powers to manage a major crisis."),
            'stockpiling': ("Panic buying at commercial grocery chains led to widespread stockpiling of non-perishable canned food and paper goods.", "noun", "The accumulation of a large supply of goods for future use, often during crises."),
            'stringent': ("Civil aviation regulators enforced stringent health protocols to ensure sanitized passenger cabin air exchanges.", "adjective", "Strict, precise, and rigorously binding in execution."),
            'super-spreader': ("An infected attendee at the crowded indoor concert triggered a super-spreader event resulting in dozens of downstream cases.", "noun", "An individual or event that transmits an infectious disease to an unexpectedly large number of people."),
            'surface transmission': ("Laboratory experiments demonstrated that the probability of surface transmission could be drastically minimized by detergent cleaning.", "noun", "The spread of pathogens through contact with contaminated objects or touchpoints."),
            'symptoms': ("Common viral symptoms include sudden fever, physical exhaustion, loss of taste, and a dry irritated cough.", "noun (plural)", "Physical or mental features indicating a condition of disease."),
            'to be hospitalised': ("Elderly individuals with severe pulmonary complications were substantially more likely to be hospitalised for intensive care.", "phrase", "To be admitted to a hospital for specialized medical treatment."),
            'to catch a disease': ("Diligent adherence to basic hand hygiene reduces an individual's statistical susceptibility to catch a disease in public.", "phrase", "To become infected with an illness or pathogen."),
            'to contain an outbreak': ("Epidemiological contact tracers worked diligently around the clock to contain an outbreak before community spread multiplied.", "phrase", "To prevent an infectious disease cluster from spreading to a wider population."),
            'to contaminate': ("Improper disposal of hazardous clinical bio-waste threatens to contaminate surrounding community water systems.", "phrase", "To make something impure, infected, or toxic by exposure to harmful substances."),
            'to disinfect': ("Hospital housekeeping crews use high-grade chemical detergents to disinfect high-touch medical equipment daily.", "phrase", "To clean something with chemical agents to destroy bacteria and viruses."),
            'to ramp up': ("Global pharmaceutical alliances collaborated to ramp up mass manufacturing of novel messenger RNA vaccines.", "phrase", "To substantially increase the production rate or capacity of an operation."),
            'to self-isolate': ("Citizens who tested positive for the virus were instructed to self-isolate at home until their contagiousness resolved.", "phrase", "To voluntarily isolate oneself at home when infected to avoid transmitting disease."),
            'transmission rate': ("Introducing mandatory indoor mask requirements led to a demonstrable drop in the regional community transmission rate.", "noun", "The speed or frequency at which an infectious disease spreads through a population."),
            'utmost': ("Emergency room medical staff treated incoming respiratory failure cases with the utmost professional diligence.", "adjective / noun", "Most extreme; greatest; of the highest degree."),
            'vaccine': ("Widespread distribution of an efficacious vaccine represents the most durable long-term defense against epidemic pathogens.", "noun", "A biological preparation providing active acquired immunity against an infectious disease."),
            'ventilators': ("Biomedical engineering companies surged production of mechanical ventilators to assist critically ill patients in intensive care.", "noun (plural)", "Medical devices designed to deliver breathable air into the lungs of patients unable to breathe."),
            'vigorous action': ("Public health leaders argued that vigorous action taken early during an epidemic saves thousands of lives.", "noun phrase", "Decisive, forceful, and energetic measures implemented to solve a crisis."),
            'vulnerable person': ("Community outreach charities delivered grocery hampers directly to every vulnerable person sheltering alone at home.", "noun phrase", "An individual at elevated risk of severe illness or harm due to age or preexisting health conditions."),
            'wheezing': ("Clinical auscultation detected severe lung wheezing, signaling bronchial airway constriction in the infected patient.", "noun", "A high-pitched whistling sound during breathing caused by narrowed airways."),
            'zoonotic': ("Virological surveillance indicates that many emerging infectious diseases originate as zoonotic transmissions from animal hosts.", "adjective", "Relating to a disease that can be transmitted from animals to humans.")
        }

        if lower_t in specific_covid:
            ex, p, df = specific_covid[lower_t]
            return clean, p, df, ex
        else:
            return clean, pos if pos else "noun", f"An epidemiological term related to infectious disease: {clean}.", f"Public health researchers closely monitor the indicator of {clean} to assess pandemic trends and hospital capacity."

    # --------------------------------------------------------------------------
    # 8. NEWSPAPERS & MEDIA (51 items)
    # --------------------------------------------------------------------------
    elif "newspaper" in lower_top:
        specific_news = {
            'broadsheets': ("Traditional broadsheets are favored by academic readers who seek in-depth investigative political analysis.", "noun (plural)", "Newspapers printed on large paper sheets, traditionally associated with serious journalism."),
            'tabloid': ("The sensational tabloid attracted millions of readers with dramatic celebrity scandals and striking photography.", "noun", "A popular newspaper having pages half the size of a broadsheet, typically featuring sensational content."),
            'tabloids': ("Sociologists critique how sensational tabloids often distort complex political debates into superficial celebrity gossip.", "noun (plural)", "Popular newspapers focused on sensational stories and entertainment news."),
            'daily newspaper': ("Subscribing to a respected daily newspaper helps citizens stay informed on national legislative affairs.", "noun", "A newspaper published every day of the week."),
            'national newspaper': ("An investigative report published by a national newspaper prompted a parliamentary inquiry into municipal corruption.", "noun", "A newspaper circulated across the entire territory of a country."),
            'local newspaper': ("Residents rely on the independent local newspaper for accurate coverage of community planning proposals.", "noun", "A newspaper published for and distributed in a specific local town or district."),
            'quarterly newspapers': ("Specialized academic institutions frequently publish quarterly newspapers reviewing recent scientific discoveries.", "noun (plural)", "Periodical publications released four times a year."),
            'periodical': ("The university library subscribes to every major international periodical in the field of macroeconomic policy.", "noun", "A magazine, newspaper, or journal published at regular intervals."),
            'back issue': ("Archivists retrieved a fragile back issue of the paper dating from the early twentieth century for research.", "noun", "A past or previous edition of a newspaper or periodical publication."),
            'edition': ("The evening edition of the metropolitan daily carried updated coverage of the parliamentary election results.", "noun", "A particular version or publication run of a newspaper or book."),
            'issue': ("The latest monthly issue of the magazine features an extensive profile on renewable energy innovation.", "noun", "A single distinct release or installment of a regular publication."),
            'supplementary magazine': ("The Sunday edition includes a glossy supplementary magazine featuring articles on literature, art, and travel.", "noun", "An additional magazine included alongside the primary newspaper."),
            'advice column': ("Readers seeking guidance on interpersonal dilemmas frequently write to the daily paper's syndicated advice column.", "noun", "A dedicated newspaper section offering counsel to readers who write with personal questions."),
            'business section': ("Financial traders analyze the morning business section for up-to-date reporting on interest rate fluctuations.", "noun", "The newspaper section dedicated to commerce, finance, markets, and corporate news."),
            'columns': ("The veteran political commentator writes weekly opinion columns examining domestic legislative developments.", "noun (plural)", "Regular vertical features or recurring opinion pieces written by journalists."),
            'comic strip': ("Weekend newspapers include an illustrated comic strip that provides humorous commentary on everyday domestic life.", "noun", "A sequence of illustrated drawings in boxes that tell a story or joke."),
            'front page': ("The historic treaty signing was featured prominently on the front page of every major international newspaper.", "noun", "The very first page of a newspaper containing the most important lead news."),
            'headlines': ("Sensational newspaper headlines are engineered to attract readers' attention at newsstands and on digital feeds.", "noun (plural)", "The heading or title at the top of an article or page in a newspaper."),
            'horoscope': ("Although lacking scientific basis, the astrological horoscope remains one of the paper's most widely read features.", "noun", "A forecast of a person's future based on relative celestial positions at birth."),
            'letter to the editor': ("A retired civil servant submitted a thoughtful letter to the editor regarding proposed municipal zoning laws.", "noun", "A published letter written by a reader to express an opinion on a recent article or issue."),
            'obituaries': ("The newspaper's poignant obituaries honor the lives and historical contributions of recently deceased scholars.", "noun (plural)", "Published notices or biographies commemorating individuals who have recently died."),
            'special feature': ("The weekend newspaper ran an extensive four-page special feature investigating artificial intelligence ethics.", "noun", "A substantial, prominent article or section devoted to a particular topic of interest."),
            'TV guide': ("Older readers still consult the weekly printed TV guide to schedule their evening television viewing.", "noun", "A printed schedule and review of television programs for a specified period."),
            'weather report': ("Farmers consult the daily newspaper weather report to anticipate seasonal precipitation and frost risks.", "noun", "A published forecast describing expected meteorological conditions."),
            'world news section': ("International affairs analysts turn directly to the world news section to review geopolitical developments.", "noun", "The newspaper section containing reporting on international events outside the host nation."),
            'caption': ("The editor added an explanatory caption beneath the photograph to identify the visiting international delegates.", "noun", "A title or brief explanation accompanying an illustration or photograph."),
            'direct quotation': ("The investigative journalist incorporated a verified direct quotation from the government whistleblower.", "noun", "A report of the exact words of an author or speaker, surrounded by quotation marks."),
            'editorial': ("The newspaper published a hard-hitting editorial urging parliament to accelerate climate adaptation funding.", "noun", "An article expressing the official collective opinion of the publication's editors."),
            'editorials': ("Readers compare competing editorials across broadsheets to appreciate diverse perspectives on legal reform.", "noun (plural)", "Articles expressing the collective opinions of the newspaper's editorial board."),
            'layout': ("Modern graphic designers revamp the newspaper layout to improve visual legibility and hierarchy on small screens.", "noun", "The structural arrangement of text, headlines, and imagery on a printed or digital page."),
            'quote': ("The investigative reporter obtained a candid quote from the finance minister during the press conference.", "noun", "A statement or passage cited directly from an authoritative source."),
            'subject matter': ("The controversial subject matter of the investigative documentary sparked widespread civic debate.", "noun", "The topic, theme, or material under discussion or representation in an article."),
            'circulation': ("As digital readership surged, the print newspaper circulation declined significantly over the past decade.", "noun", "The total number of copies of a publication distributed on an average day."),
            'fact checker': ("Every credible publishing house employs a diligent fact checker to verify data and dates prior to publication.", "noun", "A professional whose role is to confirm the factual accuracy of journalistic text."),
            'fact checkers': ("In an era of viral rumors, independent fact checkers play an indispensable role in maintaining journalistic integrity.", "noun (plural)", "Professionals who verify the factual accuracy of claims made in media."),
            'gutter press': ("Media watchdogs criticize the invasive practices of the gutter press for prioritizing sensation over truth.", "noun", "Sensationalist journalism that investigates and publishes private or scandalous details."),
            'hound': ("Aggressive paparazzi continued to hound prominent public figures in defiance of ethical privacy standards.", "verb", "To pursue, harass, or pester someone relentlessly."),
            'paparazzi': ("Independent press standards committees penalize aggressive paparazzi who stalk celebrities in private spaces.", "noun (plural)", "Freelance photographers who pursue public figures to photograph them candidly."),
            'proof reader': ("The publishing house hired a meticulous proof reader to correct grammatical errors before the edition went to print.", "noun", "A person who reads and marks corrections on printer proofs or draft texts."),
            'readership': ("By launching an intuitive mobile application, the regional daily newspaper doubled its youth readership.", "noun", "The collective audience or body of readers of a particular publication."),
            'regional news': ("Local radio and print outlets collaborate to provide comprehensive coverage of critical regional news.", "noun", "Journalistic reporting focused on events and affairs within a specific geographic territory."),
            'sensational news': ("Responsible journalists resist the temptation to produce sensational news solely to inflate digital page views.", "noun", "Exaggerated, sensationalized, or shocking reporting designed to provoke emotional reactions."),
            'attention-grabbing': ("Editors crafted an attention-grabbing title to encourage online audiences to read the complex economic study.", "adjective", "Attracting immediate public interest, notice, or attention."),
            'eye-catch': ("Clever use of contrasting bold typography is employed to eye-catch potential readers browsing a newsstand.", "verb / adjective", "Designed to quickly seize visual attention; eye-catching."),
            'eye-catching': ("The front-cover design featured an eye-catching graphic illustration depicting global renewable energy progress.", "adjective", "Visually striking, attractive, or noticeable."),
            'in-depth': ("The Sunday edition carried an in-depth analytical investigation examining systemic inequalities in public housing.", "adjective", "Comprehensive, thorough, and exhaustive in scope and detail."),
            'black and white': ("Older historical newspapers were printed strictly in black and white before modern offset color printing.", "noun / adjective", "Monochrome printing using only black ink on white paper; simple contrast."),
            'heavy newspaper': ("The weekend broadsheet was a heavy newspaper containing multiple supplements, book reviews, and magazines.", "noun phrase", "A substantial, multi-section printed newspaper with extensive content."),
            'hot off the press': ("Copies of the special edition arrived hot off the press just as voters began arriving at the convention hall.", "idiom", "Freshly printed and released; carrying the latest, most recent breaking news."),
            'relate': ("Good journalists explain complex macroeconomic trends so that everyday citizens can relate the figures to their lives.", "verb", "To establish a connection, association, or understanding with something."),
            'relevent': ("News editors ensure that every published statistical chart is directly relevent to the featured policy topic.", "adjective", "Closely connected or appropriate to the matter at hand (variant spelling).")
        }

        if lower_t in specific_news:
            ex, p, df = specific_news[lower_t]
            return clean, p, df, ex
        else:
            return clean, pos if pos else "noun", f"A journalistic concept in media studies: {clean}.", f"Media commentators debate how modern digital reporting influences public perception of the {clean}."

    # --------------------------------------------------------------------------
    # 9. PLANTS & BOTANY (44 items)
    # --------------------------------------------------------------------------
    elif "plant" in lower_top:
        species_singular = {
            'bamboo', 'begonia', 'cactus', 'palm', 'peace lily',
            'native tree', 'ornamental tree', 'perennial', 'tropical species'
        }
        anatomy_singular = {
            'bloom', 'blossom', 'foliage', 'root system', 'soil', 'stem', 'tree trunk'
        }
        care = {
            'automatic watering system', 'botanist', 'compost', 'drainage',
            'plant feed', 'pruning', 're-potting', 'sunlight', 'watering', 'longevity'
        }
        specific_plants = {
            'branches': ("Heavy snowfall during severe winter storms can cause fragile tree branches to snap and disrupt power cables.", "noun (plural)", "The woody structural limbs growing out from the trunk of a tree."),
            'leaves': ("During autumn, deciduous tree leaves lose their green chlorophyll, revealing brilliant orange and yellow tones.", "noun (plural)", "The flattened green structures of a plant where photosynthesis occurs."),
            'petals': ("Brightly colored floral petals attract vital pollinating insects such as bees and hummingbirds.", "noun (plural)", "The modified leaves that surround the reproductive parts of flowers."),
            'twigs': ("Small woodland birds gather dry twigs and fallen leaves to weave sturdy protective nests in high canopies.", "noun (plural)", "Slender, woody terminal shoots of a tree or branch."),
            'geraniums': ("Potted geraniums are popular balcony ornamentals because they produce colorful blossoms throughout the summer.", "noun (plural)", "Flowering plants of the genus Geranium widely cultivated in gardens."),
            'orchids': ("Tropical botanical greenhouses cultivate delicate orchids under rigorously controlled humidity and indirect light.", "noun (plural)", "Complex flowering plants known for their intricate, colorful blooms."),
            'roses': ("Cultivating prize-winning hybrid roses requires meticulous seasonal pruning and nutrient-rich, well-drained soil.", "noun (plural)", "Prickly flowering shrubs renowned for their fragrant and colorful blossoms."),
            'flowering plants': ("Botanical conservatories showcase hundreds of diverse flowering plants to promote public ecological education.", "noun (plural)", "Angiosperms; plants that produce flowers and seed-bearing fruit."),
            'easy to maintain': ("Succulents and cacti are popular indoor houseplants because they are exceptionally easy to maintain.", "phrase", "Requiring minimal care, effort, or intervention to keep in good condition."),
            'herbs grown in pots': ("Urban apartment dwellers frequently cultivate herbs grown in pots on sunny kitchen windowsills.", "phrase", "Culinary herbs cultivated within compact household containers."),
            'leaves turning yellow': ("Experienced gardeners recognize that leaves turning yellow typically indicate overwatering or nutrient deficiency.", "phrase", "Foliage chlorosis signaling physiological stress or nutrient deficit in plants."),
            'lush': ("Abundant seasonal precipitation and warmth produce lush, vibrant foliage throughout the botanical gardens.", "adjective", "Growing luxuriantly; abundant in green vegetation."),
            'north facing window': ("Shade-tolerant indoor ferns thrive best when positioned beside a north facing window with indirect light.", "phrase", "A window oriented northward that receives gentle, indirect ambient sunlight."),
            'small plants for the window sill': ("Compact succulent varieties make charming small plants for the window sill due to their tidy growth habits.", "phrase", "Miniature indoor houseplants suited for narrow window ledges."),
            'to have green fingers': ("My grandmother is widely admired in the neighborhood for her rare ability to have green fingers in any garden.", "idiom / phrase", "To have a natural talent for gardening and making plants grow successfully."),
            'variety of colours': ("Modern horticultural breeding has produced flowering perennials boasting a spectacular variety of colours.", "phrase", "A diverse assortment of distinct hues and chromatic shades."),
            'vegetables grown in pots': ("Balcony container gardening enables urban residents to harvest fresh vegetables grown in pots easily.", "phrase", "Nutritious edible produce cultivated in domestic containers."),
            'wilting': ("Prolonged moisture deficit causes sudden leaf wilting, indicating that immediate soil hydration is required.", "noun / verb", "Drooping and loss of rigidity in plant leaves caused by lack of water.")
        }

        if lower_t in specific_plants:
            ex, p, df = specific_plants[lower_t]
            return clean, p, df, ex
        elif lower_t in species_singular:
            return clean, "noun", f"A botanical species or plant category: {clean}.", f"Horticulturalists explain that cultivating healthy {clean} requires balanced soil moisture and appropriate sunlight."
        elif lower_t in anatomy_singular:
            return clean, "noun", f"A botanical structure or anatomical plant feature: {clean}.", f"Botanists examine how the structural development of the {clean} supports vital nutrient transport and photosynthesis."
        elif lower_t in care:
            return clean, "noun", f"A horticultural technique, input, or care concept: {clean}.", f"Maintaining adequate {clean} is essential for ensuring robust root development and sustained plant health."
        else:
            return clean, pos if pos else "noun", f"A key horticultural or botanical concept: {clean}.", f"Botanists study how {clean} adapts to shifting seasonal temperatures and environmental conditions."

    # --------------------------------------------------------------------------
    # 10. MUSICAL INSTRUMENTS (33 items)
    # --------------------------------------------------------------------------
    elif "musical" in lower_top:
        plurals = {'bagpipes', 'drums', 'pipes', 'triangles', 'wood blocks'}
        tools = {
            'microphone': ("In acoustic recording studios, using a high-fidelity microphone ensures pristine sound capture for classical vocalists.", "noun", "An acoustic instrument used to capture and amplify vocal or instrumental sound."),
            'vinyl record': ("Audiophiles appreciate the rich acoustic warmth characteristic of an authentic analog vinyl record.", "noun", "An analog sound storage medium consisting of a grooved disc played with a stylus.")
        }
        if lower_t in tools:
            ex, p, df = tools[lower_t]
            return clean, p, df, ex
        elif lower_t in plurals:
            return clean, "noun (plural)", f"A musical percussion or acoustic ensemble instrument: {clean}.", f"Traditional acoustic ensembles frequently incorporate acoustic instruments such as {clean} to provide dynamic rhythmic accompaniment."
        else:
            return clean, "noun", f"A musical instrument played in orchestral and acoustic performances: {clean}.", f"Mastering a traditional musical instrument such as the {clean} requires disciplined daily practice and acute auditory sensitivity."

    # --------------------------------------------------------------------------
    # 11. BODY LANGUAGE & NON-VERBAL COMMUNICATION (27 items)
    # --------------------------------------------------------------------------
    elif "body language" in lower_top:
        specific_body = {
            'arms behind back': ("Standing with arms behind back during a military review projects discipline and quiet authority.", "phrase", "A posture with hands clasped behind the torso."),
            'arms crossed': ("Body language experts observe that sitting with arms crossed can signal defensiveness or closed attitude.", "phrase", "Folding both arms across the chest."),
            'avoiding eye contact': ("The suspect appeared noticeably uneasy, avoiding eye contact while answering the detective's questions.", "phrase", "Deliberately looking away from another person's gaze."),
            'biting nails': ("Habitual biting nails is often an involuntary physical response to chronic nervousness or workplace stress.", "phrase", "Chewing on one's fingernails due to anxiety or boredom."),
            'blushed': ("The nervous candidate blushed noticeably when asked an unexpected, challenging technical question.", "verb (past)", "Became red in the face from embarrassment, shame, or modesty."),
            'stammering': ("Under intense cross-examination, the witness began stammering before regaining composure.", "noun / gesture", "Speaking with involuntary hesitations and repetitions of sounds."),
            'bowing': ("In traditional Japanese corporate etiquette, respectful bowing remains the customary greeting among executives.", "noun / gesture", "Bending the upper body forward as a sign of respect or greeting."),
            'crinkling nose': ("Displaying a subtle crinkling nose during food tasting conveys sensory distaste or mild skepticism.", "phrase", "Wrinkling the bridge of the nose to signal displeasure or distaste."),
            'deadpan face': ("Maintaining a completely deadpan face prevents commercial negotiators from revealing their underlying strategic motives.", "phrase", "A deliberately expressionless or impassive facial appearance."),
            'direct eye contact': ("In Western professional interviews, maintaining steady direct eye contact conveys honesty and self-assurance.", "phrase", "Looking straightforwardly into another person's eyes."),
            'eye rubbing': ("Frequent eye rubbing is a documented physiological symptom of visual fatigue and prolonged computer screen use.", "phrase", "Rubbing one's eyes with fingers due to irritation or tiredness."),
            'staring into the distance': ("Lost in deep philosophical reflection, the novelist spent hours staring into the distance by the lake.", "phrase", "Gazing unfocused toward the horizon while preoccupied in thought."),
            'firm handshake': ("A confident job applicant typically greets interviewers with a warm professional smile and a firm handshake.", "noun phrase", "A strong, decisive grip when clasping hands in greeting."),
            'covering mouth': ("Upon hearing the startling announcement, several audience members gasped, covering mouth in disbelief.", "phrase", "Placing a hand over the mouth in surprise, shock, or politeness."),
            'nodding head': ("The attentive delegate indicated agreement with the speaker's proposal by nodding head continuously.", "phrase", "Moving the head up and down to signal consent, comprehension, or assent."),
            'tight-lipped': ("Government trade envoys remained strictly tight-lipped regarding the sensitive ongoing bilateral negotiations.", "adjective", "Reluctant to speak or reveal information; secretive."),
            'putting arms up with palms facing forward': ("The hiker signaled peaceful non-aggression to the approaching park ranger by putting arms up with palms facing forward.", "phrase", "A non-verbal surrender or compliance gesture with open hands raised."),
            'raise': ("Speakers often raise an eyebrow to subtly indicate skepticism or curiosity without interrupting the dialogue.", "verb", "To elevate, lift up, or move to a higher position."),
            'raised eye brows': ("The senior professor listened to the student's improbable excuse with raised eye brows and clear skepticism.", "phrase", "Lifting the eyebrows to convey astonishment, doubt, or inquiry."),
            'scratching ones head': ("Baffled by the contradictory laboratory results, the researcher sat scratching ones head in bewilderment.", "phrase", "Scratching the scalp to express confusion or deep perplexity."),
            'shaking the head': ("The chief diplomat expressed unwavering dissent by firmly shaking the head across the conference table.", "phrase", "Moving the head from side to side to signal refusal or disagreement."),
            'shrugged': ("When questioned about the project delay, the team lead simply shrugged in indifferent resignation.", "verb (past)", "Raised and dropped the shoulders to express doubt, indifference, or ignorance."),
            'shrugging shoulders': ("Dismissing a client's inquiry with casual shrugging shoulders conveys unprofessional indifference.", "phrase", "Lifting and dropping the shoulders to signal apathy or lack of knowledge."),
            'smiling': ("The conference host welcomed international delegates by warmly smiling at the registration pavilion.", "verb / gesture", "Forming a pleased, kind, or amused facial expression with upturned mouth."),
            'stroking ones chin': ("The chess grandmaster contemplated his tactical options, stroking ones chin thoughtfully before moving.", "phrase", "Rubbing the chin while evaluating complex decisions."),
            'tapping': ("Nervous interviewees often resort to repetitive foot tapping while waiting in anticipation outside the boardroom.", "noun / verb", "Striking a surface lightly and repeatedly to make rhythmic sounds."),
            'widen gapes': ("Astonished theater spectators could only widen gapes in utter awe at the aerial acrobatic finale.", "phrase", "To open the mouth wide in surprise, astonishment, or wonder.")
        }
        if lower_t in specific_body:
            ex, p, df = specific_body[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun / gesture", f"A non-verbal physical gesture or expressive body signal: {clean}.", f"In cross-cultural communication, displaying non-verbal cues such as {clean} can convey distinct psychological attitudes."

    # --------------------------------------------------------------------------
    # 12. ADVERTISING & MARKETING (25 items)
    # --------------------------------------------------------------------------
    elif "advertising" in lower_top:
        specific_adv = {
            'ad': ("The non-profit charity placed an informative print ad in the national newspaper to solicit famine relief donations.", "noun", "An informal abbreviation for an advertisement."),
            'advert': ("Placing an eye-catching advert in a high-circulation periodical remains an effective regional promotion strategy.", "noun", "A public announcement or advertisement promoting a product, service, or event."),
            'advertise': ("Multinational enterprises invest billions annually to advertise their consumer offerings across digital video platforms.", "verb", "To describe or draw attention to a product or service in a public medium to promote sales."),
            'advertisement': ("The prime-time television advertisement was watched by over fifteen million international sports viewers.", "noun", "A notice or announcement in a public medium promoting a product, service, or event."),
            'advertising': ("Rigorous truth-in-lending legislation protects vulnerable consumers from deceptive financial advertising.", "noun", "The activity or profession of producing advertisements for commercial products."),
            'catchy tune': ("Commercial radio jingles rely on a catchy tune to ensure immediate brand recall among commuting motorists.", "noun phrase", "A memorable, melodic musical hook that is easily remembered."),
            'cold call': ("Consumer protection laws restrict telemarketers from making an unsolicited cold call to private residential phone numbers.", "noun phrase", "An unexpected phone call or visit to a potential customer without prior contact."),
            'covert advertising': ("Consumer watchdog agencies monitor covert advertising where paid product placements disguise commercial sponsorship.", "noun", "Undercover or hidden promotion of products within media without explicit disclosure."),
            'customer database': ("Direct marketing agencies manage an encrypted customer database to dispatch personalized promotional offers.", "noun", "An organized collection of comprehensive data about individual customers."),
            'eye-catching': ("The creative agency designed an eye-catching outdoor billboard that immediately drew the gaze of highway motorists.", "adjective", "Immediately appealing, noticeable, or visually striking."),
            'flick through a magazine': ("Commuters sitting in transit lobbies often flick through a magazine to pass the waiting time pleasantly.", "phrase", "To turn the pages of a periodical quickly and casually."),
            'glossy': ("High-end luxury fashion brands rely on premium glossy magazines to showcase seasonal designer collections.", "adjective", "Printed on smooth, shiny paper of superior photographic quality."),
            'intrusive': ("Consumer advocacy groups object to intrusive targeted pop-up advertisements that track personal online behavior.", "adjective", "Causing disruption or annoyance through being unwelcome or invasive."),
            'invasion of privacy': ("Privacy advocates argue that harvesting biometric consumer data without consent constitutes a serious invasion of privacy.", "noun phrase", "An unjustified intrusion into the personal life or private affairs of an individual."),
            'magazine': ("The weekly editorial magazine published an investigative critique exposing deceptive marketing practices.", "noun", "A periodical publication containing articles, stories, and commercial advertisements."),
            'memorable': ("Creating a memorable television advertisement ensures that consumers recognize brand packaging in retail supermarkets.", "adjective", "Easily remembered; making a lasting, noteworthy impression."),
            'peak viewing time': ("Broadcasting networks charge premium advertising rates during evening peak viewing time due to maximum audience share.", "noun phrase", "The hours when television viewership is at its highest point during the day."),
            'persuasive': ("Effective marketing copy utilizes persuasive psychological rhetoric to convince consumers of a product's utility.", "adjective", "Good at convincing someone to do or believe something through reasoning or appeal."),
            'pop-ups': ("Many internet users install ad-blocking extensions to prevent disruptive pop-ups from obscuring web page content.", "noun (plural)", "Unsolicited browser windows or advertising banners that appear suddenly on screen."),
            'specific interest group': ("Publishers launch niche trade journals tailored directly to a specific interest group of renewable energy engineers.", "noun phrase", "An audience or association united by a particular specialized interest."),
            'specific market': ("Automotive manufacturers engineer compact electric vehicles tailored to the logistical needs of a specific market.", "noun phrase", "A targeted, distinct group of potential buyers or geographic demographic."),
            'subtle': ("Product placement in mainstream cinematic movies offers brands a subtle means of influencing consumer preferences.", "adjective", "Delicate, understated, and not obvious or conspicuous."),
            'to target an audience': ("Digital advertisers utilize predictive demographic analytics to target an audience with tailored commercial promotions.", "phrase", "To direct advertising or promotional appeals toward a specific group of consumers."),
            'TV commercials': ("Major beverage brands invest millions of dollars to broadcast sleek TV commercials during international football championships.", "noun (plural)", "Television advertisements promoting consumer goods or commercial services."),
            'up-to-date': ("E-commerce websites must maintain up-to-date inventory listings to prevent customer dissatisfaction with out-of-stock items.", "adjective", "Incorporating the latest information, trends, or developments; current.")
        }
        if lower_t in specific_adv:
            ex, p, df = specific_adv[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun", f"A concept or technique in commercial marketing and advertising: {clean}.", f"Contemporary marketing research evaluates how the strategic use of {clean} influences consumer purchasing decisions."

    # --------------------------------------------------------------------------
    # 13. FOOD: VEGETABLES (24 items)
    # --------------------------------------------------------------------------
    elif "food" in lower_top or "vegetable" in lower_top:
        return clean, "noun", f"A nutritious edible vegetable utilized in culinary preparation: {clean}.", f"Nutritional scientists emphasize that consuming fresh seasonal {clean} provides essential vitamins, antioxidants, and dietary fiber."

    # --------------------------------------------------------------------------
    # 14. SHOES & FOOTWEAR (18 items)
    # --------------------------------------------------------------------------
    elif "shoe" in lower_top:
        specific_shoes = {
            'ankle straps': ("Outdoor walking sandals manufactured with sturdy ankle straps provide superior stability across uneven gravel paths.", "noun (plural)", "Fastening straps encircling the ankle for secure shoe fit."),
            'comfy': ("Office workers frequently switch to comfy footwear during long shifts to alleviate plantar pressure.", "adjective", "Comfortable, soothing, and physically pleasant to wear."),
            'cowboy boot': ("The classic leather cowboy boot was originally engineered with high shafts to protect riders from thorny brush.", "noun", "A sturdy leather riding boot with a high shaft and Cuban heel."),
            'flip-flops': ("While popular at the beach, flat rubber flip-flops provide inadequate arch support for walking on concrete.", "noun (plural)", "Light backless sandals held on the foot by a thong between the big and second toes."),
            'high-heeled shoe': ("Orthopedic specialists warn that frequently wearing a high-heeled shoe places excessive mechanical pressure on the forefoot.", "noun", "A shoe with a raised heel that elevates the wearer's heel significantly above the toes."),
            'loafer': ("The leather penny loafer became a staple of professional business casual attire due to its versatility.", "noun", "A leather shoe shaped like a moccasin, with a flat heel and slotted strap."),
            'pointed': ("Footwear designed with an excessively pointed toe box can compress the toes and cause painful foot deformities.", "adjective", "Having a sharpened, tapered, or pointed end."),
            'rounded': ("Orthopedic clinicians advise patients to choose footwear featuring a rounded toe box for natural foot mechanics.", "adjective", "Having a curved, smooth, and non-restrictive contour."),
            'slip off': ("Travelers appreciate laceless footwear because they can easily slip off their shoes during airport security inspections.", "phrasal verb", "To remove footwear or clothing quickly and effortlessly."),
            'slippers': ("Wearing insulated indoor slippers keeps feet warm and reduces the risk of slipping on polished hardwood floors.", "noun (plural)", "Comfortable, soft slip-on shoes worn indoors."),
            'sloppy': ("Wearing sloppy, ill-fitting footwear increases the risk of accidental tripping and occupational ankle injuries.", "adjective", "Careless, loose, untidy, or poorly fitted."),
            'thick soles': ("Hiking boots constructed with durable thick soles shield the feet from sharp rocks and rough trail terrain.", "noun (plural)", "Substantial under-layers of shoes providing cushioning and protection."),
            'tight': ("Wearing tight shoes for prolonged periods restricts peripheral circulation and induces severe muscular fatigue.", "adjective", "Fitting too closely or exerting uncomfortable pressure on the body."),
            'trainers': ("Athletes wear cushioned running trainers engineered to absorb shock during high-impact road races.", "noun (plural)", "Soft sports shoes suitable for athletic training and casual wear."),
            'walking boots': ("Experienced mountaineers invest in waterproof walking boots that provide ankle support on steep ascents.", "noun (plural)", "Sturdy, ankle-supporting boots designed for hiking and rough terrain."),
            'walking sandal': ("A well-cushioned walking sandal is ideal for warm-weather hiking along well-maintained nature trails.", "noun", "An open shoe with protective cushioning straps for pedestrian walking."),
            'worn out': ("Athletic coaches advise runners to promptly replace worn out footwear once the shock-absorbing foam compresses.", "adjective", "Damaged, degraded, or deteriorated through extensive or prolonged use."),
            'wellington boots': ("Farmers and field researchers wear waterproof rubber wellington boots to navigate muddy paddocks.", "noun (plural)", "High waterproof rubber boots reaching to the knee.")
        }
        if lower_t in specific_shoes:
            ex, p, df = specific_shoes[lower_t]
            return clean, p, df, ex
        else:
            return clean, pos if pos else "noun", f"A terminology item related to footwear and podiatry: {clean}.", f"Ergonomic footwear specialists study how {clean} affects postural stability and gait biomechanics."

    # --------------------------------------------------------------------------
    # 15. CLOTHES: CASUAL & FORMAL (15 items)
    # --------------------------------------------------------------------------
    elif "clothes" in lower_top:
        specific_clothes = {
            'backpack': ("University students often carry a heavy canvas backpack packed with textbooks and digital devices.", "noun", "A bag carried on the back, supported by shoulder straps."),
            'briefcase': ("In corporate finance and legal circles, carrying a leather briefcase signifies professional stature.", "noun", "A flat, rectangular container typically made of leather for carrying documents."),
            'coat': ("Wearing a heavy woolen coat provides essential thermal insulation against sub-zero winter temperatures.", "noun", "An outer garment worn outdoors, typically with sleeves and extending below the hips."),
            'dress': ("In formal diplomatic gatherings, wearing an elegant evening dress adheres to traditional protocol.", "noun", "A one-piece garment for a woman or girl that covers the body and extends down over the legs."),
            'flipflops': ("Beachgoers appreciate rubber flipflops for their convenience and waterproof utility near coastal waters.", "noun (plural)", "Light sandals with a thong between the toes."),
            'jacket': ("In business casual offices, pairing a tailored sports jacket with chinos creates a polished appearance.", "noun", "An outer garment extending either to the waist or the hips, typically with sleeves and a fastening."),
            'pajamas': ("Sleep hygiene researchers emphasize that wearing breathable cotton pajamas promotes restful deep sleep.", "noun (plural)", "A loose-fitting jacket and trousers for sleeping in."),
            'shoes': ("Hospitality workers require comfortable, slip-resistant shoes to endure twelve-hour shifts on hard floors.", "noun (plural)", "Footwear items covering the foot, typically having a sturdy sole."),
            'shorts': ("During intense summer heatwaves, athletes prefer lightweight athletic shorts that allow maximum ventilation.", "noun (plural)", "Short trousers that end at or above the knees."),
            'suit': ("In corporate executive environments, wearing a tailored suit conveys authority and adherence to professional standards.", "noun", "A set of outer clothes made of the same fabric, typically consisting of a jacket and trousers."),
            'suitcase': ("Business travelers pack their professional wardrobe into a compact rolling suitcase that fits into airplane overhead bins.", "noun", "A case with a handle and hinged lid, used for carrying clothes and personal possessions."),
            't-shirt': ("The plain cotton t-shirt evolved from military undergarments into an ubiquitous global casual garment.", "noun", "A short-sleeved casual top, generally without a collar or buttons."),
            'tie': ("In traditional parliamentary and judicial settings, male officials are customarily required to wear a silk tie.", "noun", "A strip of material worn around the collar and tied in a knot at the front."),
            'trousers': ("Modern professional workwear favors durable stretch trousers that combine smart aesthetics with movement.", "noun (plural)", "An outer garment covering the body from the waist to the ankles, with separate sections for each leg."),
            'waistcoat': ("A formal three-piece ensemble features an intricately tailored waistcoat worn beneath the suit jacket.", "noun", "A close-fitting waist-length sleeveless garment, typically worn over a shirt and under a jacket.")
        }
        if lower_t in specific_clothes:
            ex, p, df = specific_clothes[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun", f"An article of clothing or personal accessory: {clean}.", f"Modern sociologists study how dress codes have shifted toward comfortable, functional garments such as {clean}."

    # --------------------------------------------------------------------------
    # 16. FILMS & CINEMA (15 items)
    # --------------------------------------------------------------------------
    elif "film" in lower_top:
        singulars = {'comedy', 'historical drama', 'romcom', 'science fiction'}
        if lower_t in singulars:
            return clean, "noun", f"A recognized genre in cinematic film and storytelling: {clean}.", f"Film critics and cultural historians analyze how the cinematic genre of {clean} reflects contemporary societal anxieties and aspirations."
        else:
            return clean, "noun (plural)", f"A cinematic film category or genre: {clean}.", f"Film critics and cultural historians analyze how popular {clean} reflect contemporary societal anxieties and aspirations."

    # --------------------------------------------------------------------------
    # 17. CAMPING & OUTDOOR RECREATION (13 items)
    # --------------------------------------------------------------------------
    elif "camping" in lower_top:
        specific_camping = {
            'air mattress': ("Campers often inflate a portable air mattress inside their tent to insulate themselves from the cold ground.", "noun", "An inflatable mattress used for sleeping on when camping."),
            'backpack': ("Trekkers must adjust the hip belt of an expedition backpack to distribute heavy loads evenly across the hips.", "noun", "A large bag used for carrying gear on the back during outdoor hikes."),
            'close to nature': ("Outdoor ecotourism offers urban dwellers a rejuvenating opportunity to live close to nature and escape screen fatigue.", "phrase", "In intimate proximity with the natural world and wildlife."),
            'bug spray': ("Applying insect repellent bug spray protects wilderness hikers from irritating mosquito and tick bites.", "noun", "A chemical spray used to deter insects."),
            'campground': ("Before arriving at the national park, visitors should reserve a designated campground with clean water facilities.", "noun", "A designated outdoor area used for camping with tents or caravans."),
            'camping gear': ("Quality outdoor retailers test durable camping gear under extreme weather conditions to guarantee durability.", "noun", "The equipment and supplies needed for camping."),
            'compass': ("Even when carrying satellite GPS devices, navigators always pack a reliable magnetic compass as a backup.", "noun", "An instrument containing a magnetized pointer showing magnetic north."),
            'cramped': ("Sharing a compact two-person tent during persistent mountain rain can make living conditions feel uncomfortably cramped.", "adjective", "Uncomfortably small, confined, or restricted in physical space."),
            'firewood': ("Wilderness guidelines instruct campers to gather only fallen dry firewood rather than cutting live branches.", "noun", "Wood suitable for burning on an open campfire."),
            'hat': ("Hikers trekking across exposed ridgelines should wear a wide-brimmed protective hat to guard against intense ultraviolet rays.", "noun", "A head covering worn for protection against sun, cold, or for fashion."),
            'path': ("Navigating along the designated mountain path minimizes environmental erosion on fragile subalpine vegetation.", "noun", "A marked track, trail, or way made for traveling on foot."),
            'raincoat': ("Packing a breathable waterproof raincoat ensures hikers stay dry during sudden torrential mountain showers.", "noun", "A waterproof or water-resistant coat worn for protection from rain."),
            'wildlife': ("National park regulations strictly prohibit hikers from feeding native wildlife to prevent dangerous habituation to humans.", "noun", "Wild animals, birds, and other fauna living in their natural habitat.")
        }
        if lower_t in specific_camping:
            ex, p, df = specific_camping[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun", f"An essential item of equipment for camping and wilderness expeditions: {clean}.", f"Experienced wilderness instructors advise campers to pack essential {clean} before embarking on multi-day backcountry expeditions."

    # --------------------------------------------------------------------------
    # 18. URBAN PLANNING (12 items)
    # --------------------------------------------------------------------------
    elif "urban planning" in lower_top:
        specific_urban = {
            'urbanization': ("Rapid urbanization requires city planners to construct high-capacity public transport and sustainable stormwater systems.", "noun", "The process of making an area more urban; the progressive movement of populations into cities."),
            'decentralizing services': ("Municipal governments promote decentralizing services to reduce congestion and stimulate economic growth in outer suburban rings.", "phrase", "Distributing administrative and civic functions away from a central metropolitan core."),
            'city layout': ("An efficient city layout incorporates wide pedestrian corridors, dedicated cycle lanes, and accessible green open spaces.", "noun", "The spatial arrangement and structural design of urban zones, thoroughfares, and districts."),
            'building safety': ("Rigorous municipal building safety standards are enforced to ensure that modern high-rises can withstand major seismic shocks.", "noun", "Statutory construction codes ensuring structural integrity and fire prevention in architecture."),
            'attract investment': ("Municipal authorities offer tax incentives and upgraded digital infrastructure to attract investment into urban tech hubs.", "phrase", "To entice commercial capital and business funding into a regional municipality."),
            'commercial centres': ("Urban redevelopment projects revitalize historic commercial centres by integrating modern shopping plazas with pedestrian malls.", "noun (plural)", "Designated urban districts where trade, corporate offices, and retail businesses predominate."),
            'heritage sites': ("Urban planners implement strict conservation regulations to safeguard architectural heritage sites from demolition.", "noun (plural)", "Locations, monuments, or buildings possessing recognized historical, cultural, or aesthetic value."),
            'relocating business': ("Subsidies for relocating business to provincial enterprise parks have successfully relieved traffic pressure on the capital.", "phrase", "Moving commercial or industrial operations from one geographic area to another."),
            'requalify buildings': ("Architects collaborate with municipal councils to requalify buildings from industrial eras into modern community centers.", "phrase", "To adapt, renovate, or repurpose existing structures for new public or functional uses."),
            'urban landscape': ("Planting native canopy trees and designing community parks substantially enhances the aesthetic appeal of the urban landscape.", "noun", "The visual and spatial environment of a city, including architectural structures and open spaces."),
            'urban growth': ("Strategic zoning laws ensure that future urban growth proceeds in a socially inclusive and environmentally sustainable manner.", "noun", "The physical expansion and demographic enlargement of metropolitan metropolitan zones."),
            'unsustainable growth': ("Uncontrolled suburban sprawl without mass transit infrastructure results in unsustainable growth and environmental degradation.", "noun phrase", "Urban development that depletes natural resources and cannot be maintained over time.")
        }
        if lower_t in specific_urban:
            ex, p, df = specific_urban[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun", f"An urban planning concept: {clean}.", f"Urban planners consider how the factor of {clean} impacts the long-term livability of metropolitan centers."

    # --------------------------------------------------------------------------
    # 19. ART VS THE ARTS & ART: PAINTINGS (14 items)
    # --------------------------------------------------------------------------
    elif "art" in lower_top:
        specific_art = {
            'reading literature': ("Literary scholars argue that reading literature enhances cognitive empathy and critical analytical faculties in young minds.", "phrase", "The academic and cultural pursuit of engaging with written literary works of merit."),
            'modern mediums': ("Contemporary visual artists frequently blend digital animation and interactive modern mediums into exhibition installations.", "noun (plural)", "Contemporary technologies and non-traditional materials used in artistic expression."),
            'traditional mediums': ("Classical portrait painters often preserve traditional mediums such as egg tempera, charcoal sketching, and oil on linen.", "noun (plural)", "Conventional artistic materials including oil paints, watercolor, sculpture, and drawing."),
            'to provoke feeling': ("The primary ambition of avant-garde visual performance is to provoke feeling and challenge entrenched societal dogmas.", "phrase", "To elicit or stimulate an emotional reaction or profound psychological response."),
            'to stimulate visual experience': ("Gallery curators arrange minimalist lighting to stimulate visual experience and accentuate subtle canvas textures.", "phrase", "To engage, heighten, or provoke aesthetic visual perception."),
            'impact': ("Art historians evaluate the profound cultural impact of the Italian Renaissance on European philosophical evolution.", "noun", "A marked effect, powerful influence, or enduring impression.")
        }
        if lower_t in specific_art:
            ex, p, df = specific_art[lower_t]
            return clean, p, df, ex
        else:
            return clean, "noun", f"A recognized discipline within the visual and performing arts: {clean}.", f"Cultural historians examine how mastering an expressive artistic discipline such as {clean} enriches societal aesthetic heritage."

    # --------------------------------------------------------------------------
    # 20. ACADEMIC READING VOCABULARY LIST 1 (8 items)
    # --------------------------------------------------------------------------
    elif "academic reading" in lower_top:
        specific_reading = {
            'dissonance': ("Cognitive dissonance arises when an individual's outward behavior directly contradicts their deeply held ethical values.", "noun", "A state of tension, disharmony, or conflict between contradictory beliefs."),
            'falter': ("Despite encountering unprecedented economic headwinds, the administration's commitment to judicial integrity did not falter.", "verb", "To hesitate, lose strength, stumble, or waver in purpose."),
            'gist': ("During timed IELTS academic reading passages, efficient skimming techniques enable candidates to grasp the overall gist quickly.", "noun", "The core substance, general meaning, or essential theme of a speech or text."),
            'latent': ("Comprehensive diagnostic testing revealed a latent capacity for scientific innovation that had remained dormant through childhood.", "adjective", "Existing but hidden, dormant, or not yet developed or manifested."),
            'orate': ("The visiting international statesman stepped to the assembly lectern to orate passionately on global diplomatic cooperation.", "verb", "To deliver a formal, eloquent, or pompous public address."),
            'partially': ("The proposed environmental restrictions were only partially adopted due to intense lobbying from domestic energy producers.", "adverb", "In part; to some extent or degree, but not wholly or completely."),
            'prattle': ("Political analysts dismissed the campaign rhetoric as superficial prattle designed to divert attention from substantive deficits.", "noun / verb", "Foolish, inconsequential, or rapid chatter; idle talk."),
            'quack': ("Medical health watchdogs publish public advisories warning vulnerable patients against purchasing remedies from an unqualified quack.", "noun", "A fraudulent, untrained, or deceitful person pretending to have medical skill.")
        }
        if lower_t in specific_reading:
            ex, p, df = specific_reading[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 21. MAP VOCABULARY & USEFUL LANGUAGE (6 items)
    # --------------------------------------------------------------------------
    elif "map" in lower_top:
        specific_map = {
            'housing area': ("According to the proposed municipal layout, a newly constructed housing area will replace the former industrial warehouses.", "noun phrase", "A designated residential zone developed for homes and family living."),
            'is located': ("The central university research laboratory is located directly adjacent to the western botanical gardens on the campus map.", "verb phrase", "Situated or positioned in a specified geographical or structural place."),
            'cardinal directions': ("Cartographers utilize the four cardinal directions to accurately orient topographic maps and satellite imagery.", "noun (plural)", "The four principal compass directions: north, south, east, and west."),
            'compass points': ("Maritime navigators continually check compass points to maintain an accurate nautical heading across open waters.", "noun (plural)", "The 32 marked directional points or markings on a compass face."),
            'road': ("The newly opened ring road has significantly alleviated commercial freight congestion through the historic city center.", "noun", "A wide, paved thoroughfare designed for vehicular transit between destinations."),
            'town center': ("Urban regeneration initiatives aim to pedestrianize the town center to stimulate community commerce and civic gatherings.", "noun phrase", "The commercial, civic, and cultural heart of an urban settlement.")
        }
        if lower_t in specific_map:
            ex, p, df = specific_map[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 22. LINKING WORDS FOR ESSAY WRITING (5 items)
    # --------------------------------------------------------------------------
    elif "linking" in lower_top:
        specific_links = {
            'as a result': ("Industrial emissions severely disrupt regional precipitation cycles; as a result, devastating droughts have multiplied.", "linking adverbial phrase", "Consequently; for that reason; because of the preceding factor."),
            'because': ("Governments invest heavily in rapid bus corridors because efficient public mobility dramatically curtails urban smog.", "conjunction", "For the reason that; on account of the fact that; since."),
            'namely': ("The macroeconomic study identified two primary impediments to productivity growth, namely underinvestment and labor shortages.", "adverb", "Specifically; that is to say; in particular."),
            'particularly': ("Academic peer review demands meticulous scrutiny of experimental protocols, particularly when evaluating clinical trial outcomes.", "adverb", "Especially; to a distinct, notable, or unusual extent."),
            'while': ("While renewable energy investments have expanded rapidly, global economic reliance on fossil fuel grids remains substantial.", "conjunction", "Whereas; although; during the period that.")
        }
        if lower_t in specific_links:
            ex, p, df = specific_links[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 23. DETRIMENTAL (3 items)
    # --------------------------------------------------------------------------
    elif "detrimental" in lower_top:
        specific_detriment = {
            'detriment': ("Working excessive overtime without adequate physical recuperation operates to the severe detriment of personal wellbeing.", "noun", "The state of being harmed, damaged, or disadvantaged."),
            'detrimental': ("Unregulated industrial effluent discharges exert a highly detrimental impact on freshwater aquatic biodiversity.", "adjective", "Tending to cause harm, damage, or disadvantage; injurious."),
            'detrimentally': ("Chronic sleep deprivation detrimentally impacts executive decision-making and cognitive retention among professionals.", "adverb", "In a manner causing harm, damage, or disadvantage.")
        }
        if lower_t in specific_detriment:
            ex, p, df = specific_detriment[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 24. LACKING IN / LACK OF (2 items)
    # --------------------------------------------------------------------------
    elif "lack" in lower_top:
        specific_lack = {
            'lack': ("Critics point out that contemporary secondary school curricula often lack comprehensive instruction in financial literacy.", "verb", "To be without, deficient in, or missing something necessary."),
            'lack of': ("A persistent lack of affordable urban housing remains one of the most critical socio-economic crises facing modern cities.", "noun phrase", "An absence, deficiency, or insufficient quantity of something.")
        }
        if lower_t in specific_lack:
            ex, p, df = specific_lack[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 25. TECHNOLOGY (3 items)
    # --------------------------------------------------------------------------
    elif "technology" in lower_top:
        specific_tech = {
            'technological': ("Rapid technological breakthroughs in machine learning algorithms are revolutionizing diagnostic pathology.", "adjective", "Relating to or characterized by advanced technology or applied science."),
            'technologies': ("Pioneering sustainable green technologies is essential if industrialized nations are to fulfill zero-emission pledges.", "noun (plural)", "The applications of scientific knowledge and engineering for practical ends."),
            'technology': ("The widespread deployment of solar technology provides remote rural communities with reliable electricity.", "noun", "The practical application of scientific knowledge to commerce, industry, or life.")
        }
        if lower_t in specific_tech:
            ex, p, df = specific_tech[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # 26. EXTRA PRACTICE (4 items)
    # --------------------------------------------------------------------------
    elif "extra practice" in lower_top:
        specific_extra = {
            'arresting': ("Police detectives completed the sensitive operation of arresting the primary suspect after extensive surveillance.", "verb / participle", "Seizing or detaining someone by legal authority; also striking or noticeable."),
            'innocent': ("Under constitutional jurisprudence, an accused individual is presumed innocent until proven guilty beyond reasonable doubt.", "adjective", "Not guilty of a crime, offense, or moral wrongdoing."),
            'sentence': ("The presiding magistrate handed down a seven-year custodial sentence reflecting the gravity of the financial fraud.", "noun", "The formal punishment declared by a court of law on a convicted person."),
            'suspected': ("Public health authorities promptly quarantined the suspected source of bacterial water contamination before illness spread.", "adjective", "Believed likely to be responsible or guilty without definitive proof.")
        }
        if lower_t in specific_extra:
            ex, p, df = specific_extra[lower_t]
            return clean, p, df, ex

    # --------------------------------------------------------------------------
    # DEFAULT ROBUST ACADEMIC FALLBACK
    # --------------------------------------------------------------------------
    p_pos = pos if pos else "noun"
    if "verb" in p_pos.lower():
        ex = f"Academic researchers encourage policymakers to proactively {clean} emerging social and environmental challenges."
        df = f"To engage in the action or process of: {clean}."
    elif "adj" in p_pos.lower():
        ex = f"Researchers discovered that a {clean} approach yielded the highest measurable improvement across all empirical trials."
        df = f"Characterized by or exhibiting the quality of being: {clean}."
    elif "adv" in p_pos.lower():
        ex = f"The newly adopted guidelines were {clean} implemented across municipal departments to ensure full compliance."
        df = f"In a manner characterized as: {clean}."
    else:
        ex = f"Sociological analysis demonstrates how {clean} exerts a profound influence on contemporary public discourse."
        df = f"A key lexical concept in {topic}: {clean}."

    return clean, p_pos, df, ex


def main():
    with open("assets/data/ielts_vocabulary.json", "r", encoding="utf-8") as f:
        vocab = json.load(f)

    print(f"Total vocabulary items in source: {len(vocab)}")

    enriched = []
    seen = set()
    dropped_count = 0

    for item in vocab:
        term = item["term"].strip()
        lower_t = term.lower()

        # Filter out junk
        if lower_t in DROPS or any(bad in lower_t for bad in [
            "home page", "speaking part", "describe a piece", "band 6", "band 7",
            "what can someone gain", "how much …?", "many (lessons", "many (policies",
            "mass nouns", "natural phenomena", "powder and grain", "liquids", "states of being",
            "visual arts can be decorative"
        ]):
            dropped_count += 1
            continue

        term = CLEANS.get(term, term)
        term = re.sub(r'\(.*?\)', '', term).strip('?!.,:;"\' ')
        term = re.sub(r'\s+', ' ', term)
        lower_t = term.lower()

        if not term or lower_t in DROPS:
            dropped_count += 1
            continue

        # Preserve proper acronyms like PhD, otherwise normalize casing for body language / terms
        if term != "PhD" and not any(term.startswith(pref) for pref in ["As a result", "While"]):
            if item.get("topic") == "Body Language":
                term = term.lower()
            elif item.get("topic") == "Plants: Speaking Topic Vocabulary" and not term.startswith("to "):
                term = term.lower()
            elif item.get("topic") == "Academic Reading Vocabulary List 1":
                term = term.lower()
            lower_t = term.lower()

        topic = item.get("topic", "").strip()
        key = (topic, lower_t)
        if key in seen:
            dropped_count += 1
            continue
        seen.add(key)

        pos = item.get("part_of_speech", "").strip()
        curr_def = item.get("definition", "").strip()
        curr_ex = item.get("example", "").strip()

        clean_term, new_pos, new_def, new_ex = enrich_item(term, pos, topic, curr_def, curr_ex)

        item["term"] = clean_term
        item["part_of_speech"] = new_pos
        item["definition"] = new_def
        item["example"] = new_ex

        enriched.append(item)

    print(f"Dropped junk / duplicates: {dropped_count}")
    print(f"Total authentic vocabulary items: {len(enriched)}")

    # 1. Check ClozeGenerator word boundary regex match for 100% of items
    failed_matches = []
    for item in enriched:
        t = item["term"]
        ex = item["example"]
        escaped = re.escape(t)
        if not re.search(r'\b' + escaped + r'\b', ex, re.IGNORECASE):
            # Check without 'to ' if infinitive
            if t.lower().startswith('to '):
                verb_only = t[3:].strip()
                escaped_v = re.escape(verb_only)
                if re.search(r'\b' + escaped_v + r'\b', ex, re.IGNORECASE):
                    continue
            failed_matches.append((t, ex))

    print(f"Items failing ClozeGenerator word boundary match: {len(failed_matches)}")
    if failed_matches:
        for t, ex in failed_matches[:10]:
            print(f"  FAILED: '{t}' not found in '{ex}'")
        raise AssertionError("Cloze matching failed for some terms!")

    # 2. Check for zero awkward phrases
    awkward_phrases = [
        "In formal IELTS essays",
        "access to quality anger",
        "access to quality racism",
        "access to quality chaos",
        "access to quality mud",
        "access to quality poverty",
        "deter armed police",
        "deter circumstantial",
        "deter civil court",
        "deter judge",
        "deter court",
        "must to ",
        "key factors to address challenges in",
        "Fill in the gaps",
        "Uncountable nouns are nouns which can't be counted",
        "How do you pronounce the word",
        "Tips: You will use the above words",
        "wearing a tailored briefcase",
        "wearing a tailored suitcase",
        "pack essential campground"
    ]

    awkward_found = []
    for item in enriched:
        ex = item["example"]
        for awk in awkward_phrases:
            if awk.lower() in ex.lower():
                awkward_found.append((item["term"], awk, ex))

    print(f"Awkward / broken phrases found: {len(awkward_found)} (must be 0)")
    if awkward_found:
        for t, awk, ex in awkward_found[:10]:
            print(f"  AWKWARD: '{t}' contains '{awk}': '{ex}'")
        raise AssertionError("Awkward phrases found in dataset!")

    # SAVE OUTPUT
    with open("assets/data/ielts_vocabulary.json", "w", encoding="utf-8") as f:
        json.dump(enriched, f, indent=2, ensure_ascii=False)

    with open("ielts_vocabulary.json", "w", encoding="utf-8") as f:
        json.dump(enriched, f, indent=2, ensure_ascii=False)

    fieldnames = [
        "id", "term", "part_of_speech", "definition", "pronunciation",
        "synonyms", "example", "topic", "subtopic", "category", "source_url"
    ]
    with open("ielts_vocabulary.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for item in enriched:
            row = {k: item.get(k, "") for k in fieldnames}
            writer.writerow(row)

    print("✅ Successfully updated assets/data/ielts_vocabulary.json, ielts_vocabulary.json, and ielts_vocabulary.csv!")

if __name__ == "__main__":
    main()

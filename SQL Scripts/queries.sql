-- Question 3.1 --
SELECT chef_name, chef_surname, AVG (score) AS average_score
FROM scores
GROUP BY chef_name, chef_surname;

SELECT cuisine, AVG (score) AS average_score
FROM scores
GROUP BY cuisine;

-- Question 3.2 --
SELECT 
    ec.chef_name,
    ec.chef_surname,
    CASE 
        WHEN pe.chef_name IS NOT NULL THEN 'Participated in Episode'
        ELSE 'Not Participated in Episode'
    END AS participation_status
FROM 
    expertise_in ec
LEFT JOIN 
    participate_in_episode_as_chef pe 
    ON ec.chef_name = pe.chef_name 
    AND ec.chef_surname = pe.chef_surname
    AND pe.season = 4
WHERE 
    ec.cuisine_name = 'Japanese'
GROUP BY 
    ec.chef_name,
    ec.chef_surname,
    participation_status;

-- Question 3.3

-- Step 1: Find the maximum recipe count for chefs under 30
WITH recipe_counts AS (
    SELECT
        hr.chef_name,
        hr.chef_surname,
        COUNT(hr.recipe) AS recipe_count
    FROM
        has_recipe hr
        JOIN chefs c ON hr.chef_name = c.chef_name AND hr.chef_surname = c.chef_surname
    WHERE
        c.age < 30
    GROUP BY
        hr.chef_name,
        hr.chef_surname
),
max_recipe_count AS (
    SELECT MAX(recipe_count) AS max_count
    FROM recipe_counts
)
SELECT
    rc.chef_name,
    rc.chef_surname,
    rc.recipe_count
FROM
    recipe_counts rc
    JOIN max_recipe_count mrc ON rc.recipe_count = mrc.max_count;

-- Question 3.4 --

SELECT chef_name, chef_surname
FROM chefs
WHERE (chef_name, chef_surname) NOT IN (
    SELECT DISTINCT chef_name, chef_surname
    FROM participate_in_episode_as_judge
); 

-- Question 3.5 --

SELECT judge_name, judge_surname, COUNT(*) AS appearance_count
FROM participate_in_episode_as_judge
WHERE season = 2
GROUP BY judge_name, judge_surname
HAVING COUNT(*) > 3;

-- Question 3.6 --

-- Question 3.7 --

WITH ChefEpisodeCounts AS (
    SELECT chef_name, chef_surname, COUNT(*) AS episode_count
    FROM participate_in_episode_as_chef
    GROUP BY chef_name, chef_surname
),
MaxEpisodeCount AS (
    SELECT MAX(episode_count) AS max_count
    FROM ChefEpisodeCounts
)
SELECT c.chef_name, c.chef_surname
FROM ChefEpisodeCounts c, MaxEpisodeCount m
WHERE c.episode_count <= m.max_count - 5;

-- Question 3.8 --

-- Question 3.9 --

SELECT p.season,
       AVG(d.total_carbs) AS avg_carbs_per_season
FROM participate_in_episode_as_chef p
JOIN dietary_info d ON p.recipe_name = d.recipe
GROUP BY p.season;

-- Question 3.10 --

WITH CuisineTotalAppearances AS (
    SELECT c.cuisine_name,
           p.season,
           COUNT(*) AS appearances
    FROM participate_in_episode_as_chef p
    JOIN dietary_info d ON p.recipe_name = d.recipe
    JOIN cuisine c ON p.cuisine_name = c.cuisine_name
    GROUP BY c.cuisine_name, p.season
),
SeasonCuisineCounts AS (
    SELECT season,
           cuisine_name,
           SUM(CASE WHEN appearances > 3 THEN 1 ELSE 0 END) AS appearances_over_three
    FROM CuisineTotalAppearances
    GROUP BY season, cuisine_name
)
SELECT s1.season AS season1,
       s2.season AS season2,
       GROUP_CONCAT(s1.cuisine_name ORDER BY s1.cuisine_name) AS cuisines
FROM SeasonCuisineCounts s1
JOIN SeasonCuisineCounts s2 ON s1.season < s2.season
                             AND s1.cuisine_name = s2.cuisine_name
WHERE s1.appearances_over_three = 1
      AND s2.appearances_over_three = 1
GROUP BY season1, season2
HAVING COUNT(*) > 1;

WITH CuisineSeasonEntries AS (
    SELECT
        p.cuisine_name,
        p.season,
        COUNT(*) AS entries
    FROM
        participate_in_episode_as_chef p
    GROUP BY
        p.cuisine_name,
        p.season
    HAVING
        COUNT(*) >= 3
),
ConsecutiveSeasonEntries AS (
    SELECT
        cse1.cuisine_name,
        cse1.season AS season1,
        cse2.season AS season2,
        cse1.entries AS entries1,
        cse2.entries AS entries2
    FROM
        CuisineSeasonEntries cse1
    JOIN
        CuisineSeasonEntries cse2 ON cse1.cuisine_name = cse2.cuisine_name
                                 AND cse1.season = cse2.season - 1
)
SELECT
    cuisine_name,
    season1,
    season2,
    entries1 AS entries
FROM
    ConsecutiveSeasonEntries
WHERE
    entries1 = entries2;


-- Question 3.11 --

WITH JudgeCumulativeScores AS (
    SELECT p.chef_name,
           p.chef_surname,
           j.judge_name,
           j.judge_surname,
           SUM(p.score) AS cumulative_score
    FROM participate_in_episode_as_chef p
    JOIN participate_in_episode_as_judge j ON p.episode_no = j.episode_no AND p.season = j.season
    GROUP BY p.chef_name, p.chef_surname, j.judge_name, j.judge_surname
),
RankedJudges AS (
    SELECT chef_name,
           chef_surname,
           judge_name,
           judge_surname,
           cumulative_score,
           ROW_NUMBER() OVER(PARTITION BY chef_name, chef_surname ORDER BY cumulative_score DESC) AS rank
    FROM JudgeCumulativeScores
)
SELECT chef_name,
       chef_surname,
       judge_name,
       judge_surname,
       cumulative_score
FROM RankedJudges
WHERE rank <= 5;

-- Question 3.12 --

WITH EpisodeCumulativeDifficulty AS (
    SELECT season,
           episode_no,
           SUM(difficulty) AS cumulative_difficulty
    FROM participate_in_episode_as_chef
    JOIN recipes ON participate_in_episode_as_chef.recipe_name = recipes.recipe_name
    GROUP BY season, episode_no
),
RankedEpisodes AS (
    SELECT season,
           episode_no,
           cumulative_difficulty,
           ROW_NUMBER() OVER(PARTITION BY season ORDER BY cumulative_difficulty DESC) AS rank
    FROM EpisodeCumulativeDifficulty
)
SELECT season,
       episode_no,
       cumulative_difficulty
FROM RankedEpisodes
WHERE rank = 1;

-- Question 3.13 --

-- Question 3.14 --

-- Question 3.15 --

-- Step 1: Identify all food groups
SELECT fg.food_group_name
FROM food_groups fg
-- Step 2: Identify food groups that have appeared in the competition
LEFT JOIN (
    SELECT DISTINCT i.food_group_name
    FROM ingredients i
    JOIN has_ingredient hi ON i.ingredient_name = hi.ingredient
    JOIN participate_in_episode_as_chef p ON hi.recipe = p.recipe_name
) AS appeared_food_groups
ON fg.food_group_name = appeared_food_groups.food_group_name
-- Step 3: Find food groups that have never appeared
WHERE appeared_food_groups.food_group_name IS NULL;


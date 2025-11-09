import csv
import re

input_file = "/root/project_gitlab/projects/home/nginx/frontend/public/data/input.txt"
output_file = "/root/project_gitlab/projects/home/nginx/frontend/public/data/output.csv"

with open(input_file, "r", encoding="utf-8") as f:
    raw_text = f.read().strip()

entries = re.split(r'\n(?=\d+\t)', raw_text)
header = entries.pop(0)

with open(output_file, 'w', encoding='utf-8', newline='') as f:
    f.write('Номер ЖК,Описание\n')
    for entry in entries:
        if "С В О Б О Д Н О" not in entry:
          number, description = entry.split('\t', 1)
          description = description.strip()
          # Убираем двойные кавычки только по краям
          if description.startswith('"') and description.endswith('"'):
              description = description[1:-1]
          # Убираем двойные кавычки внутри текста
          description = description.replace('"', "'")
          f.write(f'{number},"{description}"\n')

print(f"✅ CSV сохранён в {output_file}")

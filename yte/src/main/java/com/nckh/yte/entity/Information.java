@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Information {

    @Id
    @GeneratedValue
    private UUID id;

    private String name;

    @Column(columnDefinition="TEXT")
    private String responseData;
}
